let database = {}
module.exports = database
let common = require("./common")
let units = require("./units")
let tiles = require("./tiles")
let Redis = require("ioredis")
let redis

let positionSweepSize = 100

//Converts position list into a dict of slot friendly lists with prefix prefixed to the positions
//This sweep partitions the world allowing the partitions to be divided across redis nodes
//Collections of tiles in one sweep can all be retrieved from redis with one command
//The dict key is floor(x / positionSweepSize)
//eg tile [5:7, 234:423] -> { 0 : [tile{0}5:7], 2 : [tile{2}234:423]}
function convertPositionList(positions) {
    let batches = {}

    for (let pos of positions) {
        let sweepId = Math.floor((pos.split(":")[0])/positionSweepSize)
        if (!batches[sweepId]) batches[sweepId] = []
        batches[sweepId].push(pos)
    }

    return batches
}

function convertTileList(tileList) {
    let batches = {}

    for (let tile of tileList) {
        let sweepId = Math.floor((pos.split(":")[0])/positionSweepSize)
        if (!batches[sweepId]) batches[sweepId] = []
        batches[sweepId].push(tile)
    }

    return batches
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
    let [tile] = await database.getTiles([pos])
    return tile
}

database.getTiles = async (positions) => {
    if (positions.length == 0) return []

    let data = {}
    let batches = convertPositionList(positions)

    for (let prop of tiles.TileFields)
        data[prop] = []

    for (let sweepId in batches) {
        let batch = batches[sweepId]

        if (batch.length > 0) 
            for (let prop of tiles.TileFields)
                data[prop].push(redis.hmget("tile{".concat(sweepId, prop, "}"), ...batch))
    }

    for (let prop of tiles.TileFields)
        data[prop] = (await Promise.all(data[prop])).flat()

    let tileList = []

    for (let i in data["OwnerId"]) {
        let tile = {}
        for (let prop of tiles.TileFields) {
            if (prop == "UnitList")
                tile[prop] = JSON.parse(data[prop][i])
            else
                tile[prop] = data[prop][i]
        }

        tileList.push(tile)
    }

    return tileList
}

database.getUnit = async (ownerId, id) => {
    let req = {}
    req[ownerId] = [id]
    return await database.getUnits(req)
}

// idDict = {ownerid: [id...], owner2id: [...
database.getUnits = async (idDict) => {
    let data = {}

    for (let prop of units.UnitFields)
        data[prop] = []

    for (let owner in idDict) {
        let idList = idDict[owner]

        if (idList.length > 0)
            for (let prop of units.UnitFields)
                data[prop].push(redis.hmget("unit{".concat(owner, prop, "}"), ...idList))
    }

    for (let prop of units.UnitFields)
        data[prop] = (await Promise.all(data[prop])).flat()

    let unitList = []

    for (let i in data["Id"]) {
        let unit = {}
        for (let prop of units.UnitFields)
            unit[prop] = data[prop][i]

        unitList.push(unit)
    }

    return unitList
}

database.updateUnits = async (unitList) => {
    if (unitList.length == 0) return

    let batches = convertUnitList(unitList)
    let cacheData = {}

    for (let i in batches) {
        let unitBatch = batches[i]
        let data = {}

        for (let prop of units.UnitFields)
            data[prop] = {}

        for (let unit of unitBatch){
            for (let prop of units.UnitFields)
                data[prop][unit.Id] = unit[prop]

            let sweepId = Math.floor((unit.Position.split(":")[0])/positionSweepSize)
            if (!cacheData[sweepId]) cacheData[sweepId] = {}
            cacheData[sweepId][unit.Position+"@"+unit.Id] = unit.OwnerId
        }

        for (let prop of units.UnitFields)
            redis.hmset("unit".concat("{", i, prop, "}"), data[prop])    
    }

    for (let sweepId in cacheData)
        redis.hmset("unitcache{".concat(sweepId, "}"), cacheData[sweepId])
}

database.updateUnit = (unit) => {
    database.updateUnits([unit])
}

database.getUnitIdsAtPosition = async (pos) => {
    return database.getUnitIdsAtPositions([pos])
}

database.getUnitIdsAtPositions = async (posList) => {
    
    let batches = convertPositionList(posList)
    let unculledIdList = []

    for (let sweepId in batches)
        unculledIdList.push(redis.hgetall("unitcache{".concat(sweepId, "}")))

    unculledIdList = Object.assign({}, ...(await Promise.all(unculledIdList)))

    let posSet = new Set(posList)
    let idDict = {}

    for (let key in unculledIdList) {
        [pos, id] = key.split("@")
        if (posSet.has(pos)) {
            let owner = unculledIdList[key]
            if (!idDict[owner]) idDict[owner] = []
            idDict[owner].push(id)
        }
    }
    
    return idDict
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

database.updateTile = async (pos, tile) => {
    let sweepId = Math.floor((pos.split(":")[0])/positionSweepSize)

    for (let prop of tiles.TileFields) {
        if (typeof tile[prop] == "object")
            redis.hset("tile{".concat(sweepId, prop, "}"), pos, JSON.stringify(tile[prop]))
        else
            redis.hset("tile{".concat(sweepId, prop, "}"), pos, tile[prop])
    }
}

database.updateTileProp = (prop, pos, value) => {
    let sweepId = Math.floor((pos.split(":")[0])/positionSweepSize)
    redis.hset("tile{".concat(sweepId, prop, "}"), pos, value)
}

database.deleteTile = (pos) => {
    let sweepId = Math.floor((pos.split(":")[0])/positionSweepSize)

    for (let prop of tiles.TileFields)
        redis.hdel("tile{".concat(sweepId, prop, "}"), pos)
}

database.deleteUnit = async (unitId) => {
    let pos = await database.getUnitProp(unitId, "Position")
    redis.srem("unitcache:"+positionConversion(pos), unitId)
    redis.hset("unit:Health", unitId, 0)
}

database.updateStatus = (time, status) => {
    redis.set("lastprocess", time)
    redis.set("status", status)
}

database.waitForRedis = async () => {
    return await redis.wait(1, 2000)
}
