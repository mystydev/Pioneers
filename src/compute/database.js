let database = {}
module.exports = database
let common = require("./common")
let tiles = require("./tiles")
let Redis = require("ioredis")
let redis

//The world is split into many squares with width/height of partitionSize
//These partitions allow for efficient caching of a large number of tiles
let partitionSize = 20

//Modified Cantor pairing to convert 2d partitions to 1d label
//Integers mapped to naturals to allow cantor to map every integer pair
database.findPartitionId = (pos) => {
    let [x, y] = common.strToPosition(pos)
    x = Math.floor(x / partitionSize)
    y = Math.floor(y / partitionSize)
    x = x >= 0 ? x * 2 : -x * 2 - 1
    y = y >= 0 ? y * 2 : -y * 2 - 1
    return 0.5 * (x + y) * (x + y + 1) + y
}

//Inverse cantor pairing
function findXYFromPartitionId(id) {
    id = parseInt(id)
    let w = Math.floor((Math.sqrt(8 * id + 1) - 1) / 2)
    let t = (w**2 + w) / 2
    let y = id - t
    let x = w - y
    x = x%2 ? (x + 1) / -2 : x = x / -2
    y = y%2 ? (y + 1) / -2 : y = y / -2

    return [x * partitionSize, y * partitionSize]
}

database.partitionIndex = (position) => {
    let [x, y] = common.strToPosition(position)
    x = x >= 0 ? x % partitionSize : partitionSize + x % partitionSize
    y = y >= 0 ? y % partitionSize : partitionSize + y % partitionSize
    return x * partitionSize + y
}

//Converts position list into a dict of slot friendly lists
//eg tile [5:7, 234:423] -> { 0 : [5:7...], 2 : [234:423...]}
function convertPositionList(positions) {
    let partitions = {}

    for (let pos of positions) {
        let partitionId = database.findPartitionId(pos)
        if (!partitions[partitionId]) partitions[partitionId] = []
        partitions[partitionId].push(pos)
    }

    return partitions
}

//Converts a unit list into a dict of slot friendly lists
//The dict key is the unit's owner id
function convertUnitList(unitList) {
    let batches = {}

    for (let unit of unitList) {
        if (!batches[unit.OwnerId]) batches[unit.OwnerId] = []
        batches[unit.OwnerId].push(unit)
    }

    return batches
}

function convertUnitIdList(unitIdList) {
    let batches = {}

    for (let id of unitIdList) {
        let ownerId = id.match(/\d+/)[0]
        if (!batches[ownerId]) batches[ownerId] = []
        batches[ownerId].push(id)
    }

    return batches
}

database.connect = () => {
    redis = new Redis.Cluster([{
        port: 6379,
        host: "redis.dev"
    }], {
        scaleReads: "slave"
    })

    return redis
}

database.disconnect = () => {
    redis.disconnect()
}

database.getTile = async (pos) => {
    return redis.hgetall("tile{"+database.findPartitionId(pos)+"}"+pos)
}

database.getTiles = async (positions) => {
    if (positions.length == 0) return []

    let partitions = convertPositionList(positions)
    let tileList = []
    let fetching = []

    for (let partitionId in partitions) {
        let pipeline = redis.pipeline()

        for (let pos of partitions[partitionId])
            pipeline.hgetall("tile{"+partitionId+"}"+pos, 
                (e, tile) => tile.Position && tileList.push(tiles.sanitise(tile)))

        fetching.push(pipeline.exec())
    }

    await Promise.all(fetching)
    return tileList
}

database.getStaleTilesFromVersionCache = async (partitionId, versionCache) => {
    let freshVersionCache = await redis.get("versionCache{" + partitionId + "}") || "0".repeat(partitionSize**2)

    //Exit early if given hash is valid (requestee already has up to date tiles)
    if (versionCache == freshVersionCache) return {}

    let hashes = versionCache.split("")
    let freshHashes = freshVersionCache.split("")
    let pipeline = redis.pipeline()
    let [xoffset, yoffset] = findXYFromPartitionId(partitionId)
    let tileList = []

    //Calculate the position of stale tiles and fetch them
    for (let i = 0; i < partitionSize**2; i++) {
        if (hashes[i] != freshHashes[i]) {
           
            let y = i % partitionSize
            let x = (i - y) / partitionSize
            //console.log(i, x, y, xoffset, yoffset)
            x += xoffset
            y += yoffset
            
            pipeline.hgetall("tile{"+partitionId+"}"+x+":"+y, 
                (e, tile) => tile.Position && tileList.push(tiles.sanitise(tile)))
        }
    }

    await pipeline.exec()
    return [partitionId, freshVersionCache, tileList]
}

//{partitionId: versionCache, ...} -> [[partitionId, versionCache, tiles], ...]
database.getStaleTilesFromPartitions = async (partitionDict) => {
    let updates = []

    for (let partitionId in partitionDict)
        updates.push(database.getStaleTilesFromVersionCache(partitionId, partitionDict[partitionId]))

    return await Promise.all(updates)
}

database.getUnit = async (ownerId, id) => {
    return redis.hgetall("unit{"+ownerId+"}"+id)
}

// idDict = {ownerid: [id...], owner2id: [...
database.getUnits = async (idDict) => {
    let unitList = []
    let fetching = []

    for (let owner in idDict) {
        let pipeline = redis.pipeline()

        for (let id of idDict[owner])
            pipeline.hgetall("unit{"+owner+"}"+id, 
                (e, unit) => unit.Id && unitList.push(unit))

        fetching.push(pipeline.exec())
    }

    await Promise.all(fetching)
    return unitList
}

database.updateUnits = async (unitList) => {
    if (unitList.length == 0) return

    //Get unit batches by owner id
    let batches = convertUnitList(unitList)

    //Update unit data
    for (let owner in batches) {
        let pipeline = redis.pipeline()

        for (let unit of batches[owner])
            pipeline.hmset("unit{"+owner+"}"+unit.Id, unit)

        pipeline.exec()
    }

    //Update unit cache data
    let pipelines = {}

    for (let owner in batches){
        for (let unit of batches[owner]) {
            let partitionId = String(database.findPartitionId(unit.Position))

            if (!pipelines[partitionId]) 
                pipelines[partitionId] = redis.pipeline()

            pipelines[partitionId].hset("unitCache{"+partitionId+"}", owner+":"+unit.Id, unit.Position)

            if (partitionId != unit.PartitionId) {
                if (!pipelines[unit.PartitionId]) 
                    pipelines[unit.PartitionId] = redis.pipeline()

                pipelines[unit.PartitionId].hdel("unitCache{"+unit.PartitionId+"}", owner+":"+unit.Id)
                redis.hset("unit{"+owner+"}"+unit.Id, "PartitionId", partitionId)
            }
        }
    }

    for (let partitionId in pipelines)
        pipelines[partitionId].exec()
}

database.updateUnit = (unit) => {
    database.updateUnits([unit])
}

database.getUnitIdsAtPosition = async (pos) => {
    return database.getUnitIdsAtPositions([pos])
}

database.getUnitIdsAtPositions = async (posList) => {
    console.log("Unimplemented getUnitIdsAtPositions")
}

database.getUnitIdsAtPartitions = async (partitions) => {
    console.log("Unimplemented getUnitIdsAtPartitions")
}

database.getUnitsAtPartitions = async (partitions) => {
    let idMap = {}
    let fetching = []

    for (let partitionId in partitions)
        fetching.push(redis.hgetall("unitCache{"+partitionId+"}", 
                (e, dict) => Object.assign(idMap, dict)))

    await Promise.all(fetching)

    let unitList = []
    let pipelines = {requestedPipeline: redis.pipeline()}
    fetching = []

    for (let id in idMap) {
        let [ownerId, unitId] = id.split(":")

        if (!pipelines[ownerId])
            pipelines[ownerId] = redis.pipeline()
        
        pipelines.requestedPipeline.set("requested{"+ownerId+"}", true)
        pipelines.requestedPipeline.expire("requested{"+ownerId+"}", 30)
        pipelines[ownerId].hgetall("unit{"+ownerId+"}"+unitId, 
            (e, unit) => unit.Id && unitList.push(unit))
    }

    for (let i in pipelines)
        fetching.push(pipelines[i].exec())

    await Promise.all(fetching)
    return unitList
}

database.wasIdRequested = async (id) => {
    return await redis.get("requested{"+id+"}")
}

database.getAllStats = async () => {
    let Stats = {}
    let stats = await redis.hgetall('stats')
    let num = 0

    for (let key in stats) {
        Stats[key] = JSON.parse(stats[key])
        num++
    }

    console.log("Loaded", num, "stats!")

    return Stats
}

database.getStat = (id, type) => {
    return redis.hget("stats:"+id, type)
}

database.addStat = (id, type, amount) => {
    redis.hincrby("stats:"+id, type, parseInt(amount))
}

database.setStat = (id, type, value) => {
    redis.hset("stats:"+id, type, value)
}

database.setStats = (id, stats) => {
    redis.hmset("stats:"+id, stats)
}

database.getStats = async (id) => {
    return redis.hgetall("stats:"+id)
}

database.getAllSettings = async () => {
    let Settings = {}
    let settings = await redis.hgetall('settings')
    let num = 0

    for (let key in settings) {
        Settings[key] = JSON.parse(settings[key])
        num++
    }

    console.log("Loaded", num, "user settings!")

    return Settings
}

database.getUnitCount = async () => {
    return await redis.get("unitcount")
}

database.getUnitSpawns = async (id) => {
    return redis.hgetall("unitspawns:"+id)
}

database.getUnitCollection = async (id) => {
    return redis.lrange("unitcollection:"+id, 0, -1)
}

database.getActionQueue = async (id) => {
    let actions = await redis.lrange("actionQueue:"+id, 0, -1)
    redis.ltrim("actionQueue:"+id, actions.length, -1)

    return actions
}

database.addPlayer = (id) => {
    redis.rpush("playerlist", id)
}

database.getPlayerList = async () => {
    return redis.lrange("playerlist", 0, -1)
}

database.updateSettings = (id, settings) => {
    redis.hset("settings", id, JSON.stringify(settings))
}

database.updateUnitSpawn = (id, pos, count) => {
    redis.hset("unitspawns:"+id, pos, count)
}

database.deleteUnitSpawn = (id, pos) => {
    redis.hdel("unitspawns:"+id, pos)
}

database.updateUnitCount = (count) => {
    redis.set("unitcount", count)
}

database.incrementUnitCount = () => {
    return redis.incr("unitcount")
}

database.pushUnitToCollection = (id, data) => {
    redis.rpush("unitcollection:"+id, data)
}

database.updateTile = async (position, tile) => {
    let pipeline = redis.pipeline()

    //Update tile definition
    let partitionId = database.findPartitionId(position)
    pipeline.hmset("tile{"+partitionId+"}"+tile.Position, tiles.storePrep(tile))
    
    //Calculate location of tile in partition hash
    let cacheIndex = database.partitionIndex(position)

    //0 = grass, 1 = walkable, 2 = non-walkable, 3 = storage,
    let walkableVal = !(tiles.getSafeType(tile) == tiles.TileType.GRASS) + !tiles.isWalkable(tile, true) + tiles.isStorageTile(tile)
    //How many adjacent tiles of the same type are there
    let neighbours = await tiles.getNeighbours(position)
    let adjacentVal = await tiles.getNumberOfSimilarAdjacentTiles(tile, neighbours)

    //Update fast lookup partition caches
    pipeline.setnx("versionCache{"+partitionId+"}", "0".repeat(partitionSize**2))
    pipeline.setnx("fastPathCache{"+partitionId+"}", "0".repeat(partitionSize**2))
    pipeline.setnx("adjacencyCache{"+partitionId+"}", "0".repeat(partitionSize**2))
    pipeline.bitfield("versionCache{"+partitionId+"}", "SET", "u8", cacheIndex * 8, 48 + tile.CyclicVersion)
    pipeline.bitfield("fastPathCache{"+partitionId+"}", "SET", "u8", cacheIndex * 8, 48 + walkableVal)
    pipeline.bitfield("adjacencyCache{"+partitionId+"}", "SET", "u8", cacheIndex * 8, 48 + adjacentVal, 
        (e, previousValue) => {if (previousValue[0] != 48 + adjacentVal) database.updateAdjacencyCaches(neighbours)})

    await pipeline.exec()
}

//Update surrounding tiles adjacency values
database.updateAdjacencyCaches = async (tileList) => {
    for (let tile of tileList) {
        if (!tile) continue

        let partitionId = database.findPartitionId(tile.Position)
        let cacheIndex = database.partitionIndex(tile.Position)
        let adjacentVal = await tiles.getNumberOfSimilarAdjacentTiles(tile)
        
        redis.setnx("adjacencyCache{"+partitionId+"}", "0".repeat(partitionSize**2))
        redis.bitfield("adjacencyCache{"+partitionId+"}", "SET", "u8", cacheIndex * 8, 48 + adjacentVal)
    }
}

database.getFastPathCache = async (partitionId) => {
    let cache = await redis.get("fastPathCache{"+partitionId+"}")
    
    if (!cache) {
        cache = "0".repeat(partitionSize**2)
        redis.set("fastPathCache{"+partitionId+"}", cache)
    }

    return cache
}

database.getAdjacencyCache = async (partitionId) => {
    let cache = await redis.get("adjacencyCache{"+partitionId+"}")
    
    if (!cache) {
        cache = "0".repeat(partitionSize**2)
        redis.set("adjacencyCache{"+partitionId+"}", cache)
    }

    return cache
}

database.updateTileProp = (prop, position, value) => {
    console.log("danger, unfinished tile prop edit")
    let partitionId = database.findPartitionId(position)
    redis.hset("tile{"+partitionId+"}"+position, prop, value)
}

database.deleteTile = (position) => {
    let partitionId = database.findPartitionId(position)
    redis.del("tile{"+partitionId+"}"+position)
}

database.updateStatus = (time, status) => {
    redis.set("lastprocess", time)
    redis.set("status", status)
}

database.waitForRedis = async () => {
    return await redis.wait(1, 2000)
}

database.setRoundStart = () => {
    redis.set("roundStart", new Date().getTime())
}
