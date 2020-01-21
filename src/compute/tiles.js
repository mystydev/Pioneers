let tiles = module.exports = {}
let performance = require('perf_hooks').performance
let database = require("./database")
let common = require("./common")
let resource = require("./resource")
let userstats = require("./userstats")
let units = require("./units")

let TileType = tiles.TileType = {
    DESTROYED:'-1',
    GRASS:'0',
    KEEP:'1',
    PATH:'2',
    HOUSE:'3',
    FARM:'4',
    MINE:'5',
    FORESTRY:'6',
    STORAGE:'7',
    BARRACKS:'8',
    WALL:'9',
    GATE:'10',
    OTHERPLAYER:'1000',
};

let defaults = tiles.defaults = {}
tiles.defaults[TileType.GRASS]    = {}
tiles.defaults[TileType.KEEP]     = {Type:TileType.KEEP, Health:1000}
tiles.defaults[TileType.PATH]     = {Type:TileType.PATH, Health:100}
tiles.defaults[TileType.HOUSE]    = {Type:TileType.HOUSE, Health:200}
tiles.defaults[TileType.FARM]     = {Type:TileType.FARM, Health:100}
tiles.defaults[TileType.MINE]     = {Type:TileType.MINE, Health:100}
tiles.defaults[TileType.FORESTRY] = {Type:TileType.FORESTRY, Health:100}
tiles.defaults[TileType.STORAGE]  = {Type:TileType.STORAGE, Health:300}
tiles.defaults[TileType.BARRACKS] = {Type:TileType.BARRACKS, Health:1000}
tiles.defaults[TileType.WALL]     = {Type:TileType.WALL, Health:10000}
tiles.defaults[TileType.GATE]     = {Type:TileType.GATE, Health:10000}

let TileConstructionCosts = tiles.TileConstructionCosts = {}
TileConstructionCosts[TileType.KEEP]     = {Stone:0,     Wood:0};
TileConstructionCosts[TileType.PATH]     = {Stone:20,    Wood:0};
TileConstructionCosts[TileType.HOUSE]    = {Stone:100,   Wood:150};
TileConstructionCosts[TileType.FARM]     = {Stone:75,    Wood:75};
TileConstructionCosts[TileType.MINE]     = {Stone:0,     Wood:150};
TileConstructionCosts[TileType.FORESTRY] = {Stone:150,   Wood:0};
TileConstructionCosts[TileType.STORAGE]  = {Stone:1000,  Wood:1300};
TileConstructionCosts[TileType.BARRACKS] = {Stone:3000,  Wood:3000};
TileConstructionCosts[TileType.WALL]     = {Stone:1000,  Wood:1000};
TileConstructionCosts[TileType.GATE]     = {Stone:1000,  Wood:1500};

let TileMaintenanceCosts = tiles.TileMaintenanceCosts = {}
TileMaintenanceCosts[TileType.KEEP]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.PATH]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.HOUSE]    = {Stone:0.3,   Wood:0.3};
TileMaintenanceCosts[TileType.FARM]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.MINE]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.FORESTRY] = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.STORAGE]  = {Stone:0.2,   Wood:0.2};
TileMaintenanceCosts[TileType.BARRACKS] = {Stone:0.5,   Wood:0.5};
TileMaintenanceCosts[TileType.WALL]     = {Stone:0.1,   Wood:0.1};
TileMaintenanceCosts[TileType.GATE]     = {Stone:0.1,   Wood:0.1};

let TileOutputs = {}
TileOutputs[TileType.FARM]     = resource.Type.FOOD
TileOutputs[TileType.FORESTRY] = resource.Type.WOOD
TileOutputs[TileType.MINE]     = resource.Type.STONE

let TilesRequiringStorage = tiles.TilesRequiringStorage = {}
TilesRequiringStorage[TileType.HOUSE] = true
TilesRequiringStorage[TileType.FARM] = true
TilesRequiringStorage[TileType.FORESTRY] = true
TilesRequiringStorage[TileType.MINE] = true

tiles.TileFields = [
    "Type",
    "OwnerId",
    "Health",
    "MaxHealth",
    "UnitList",
    "Position",
]

let pathfindingBlacklist = {}

tiles.fastPathCache = {}
tiles.adjacencyCache = {}
tiles.fastUnitCollisionCache = {}
tiles.guardpostsCache = {}
tiles.highresPathingCache = {}

tiles.newTile = async (type, id, pos, unitlist) => {
    let tile = {
        Type: type,
        OwnerId: id,
        Health: defaults[type].Health,
        MaxHealth: defaults[type].Health,
        UnitList: unitlist || [],
        Position: pos,
        CyclicVersion: "0",
    }

    if (type == TileType.HOUSE && tile.UnitList.length < common.HOUSE_UNIT_NUMBER) {
        units.setSpawn(id, pos)
    }

    if (type == TileType.KEEP) {
        let neighbours = await tiles.getNeighbourPositions(pos)

        for (let p of neighbours)
            database.updateTile(p, await tiles.newTile(TileType.PATH, id, p))

        await userstats.assignKeep(id, pos)
    }

    if (type != TileType.GRASS) {
        let partitionId = common.findPartitionId(pos)
        database.setPartitionOwner(id, partitionId)
    }

    return tile
}

tiles.sanitise = (tile) => {
    tile.UnitList = tile.UnitList ? JSON.parse(tile.UnitList) : []
    return tile
}

tiles.storePrep = (tile) => {
    tile.CyclicVersion = tile.CyclicVersion % 9 + 1
    let preppedTile = {}
    Object.assign(preppedTile, tile)
    preppedTile.UnitList = JSON.stringify(preppedTile.UnitList)
    return preppedTile
}

tiles.deleteTile = async (tile) => {
    
    if (tile.Type == tiles.TileType.HOUSE) {
        for (let unitId of tile.UnitList) {
            let unit = await database.getUnit(tile.OwnerId, unitId)
            await units.handleDeath(unit)
        }
    } else {
        for (let unitId of tile.UnitList) {
            let unit = await database.getUnit(tile.OwnerId, unitId)
            await units.unassignWork(unit)
        }
    }

    await units.removeSpawn(tile.OwnerId, tile.Position)
    await database.deleteTile(tile.Position)
}

tiles.fromPosString = async (pos) => {
    return tiles.sanitise(await database.getTile(pos))
}

tiles.fromPosList = async (list) => {
    return database.getTiles(list)
}

tiles.fromCoords = (posx, posy) => {
    return database.getTile(posx + ":" + posy)
}

tiles.dbFromCoords = async (posx, posy) => {
    return await database.getTile(posx + ":" + posy) 
}

tiles.getSafeType = (tile) => {
    if (!tile) return TileType.GRASS
    return tile.Type || TileType.GRASS
}

tiles.isStorageTile = (tile) => {
    let type = tiles.getSafeType(tile)
    return (type == TileType.STORAGE || type == TileType.KEEP)
}

tiles.getNeighbours = async (pos) => {
    /*var [x, y] = common.strToPosition(pos)

    return Promise.all([
        tiles.fromCoords(x,     y    ),
        tiles.fromCoords(x,     y - 1),
        tiles.fromCoords(x + 1, y + 1),
        tiles.fromCoords(x - 1, y - 1),
        tiles.fromCoords(x + 1, y    ),
        tiles.fromCoords(x - 1, y    )
    ])*/

    return tiles.fromPosList(await tiles.getNeighbourPositions(pos))
}

tiles.getNeighbourPositions = async (pos, isMilitary) => {

    const [x, y] = common.strToPosition(pos)

    let positions = []

    //is it a whole number (center), these offsets are only valid for hexagon centers
    if (Math.floor(x) == x && Math.floor(y) == y) {
        positions = [
            (x    ) + ":" + (y + 1),
            (x    ) + ":" + (y - 1),
            (x + 1) + ":" + (y + 1),
            (x - 1) + ":" + (y - 1),
            (x + 1) + ":" + (y    ),
            (x - 1) + ":" + (y    )
        ]
    }

    if (isMilitary) {
        //If unit is walking on grass disallow hexagon centers
        if (await tiles.searchFastPathCache(pos) == 0)
            positions = []

        positions = positions.concat(tiles.getHighResNeighbourPositions(pos))
    }

    return positions
}

tiles.getHighResNeighbourPositions = (position) => {
    
    const [x, y] = common.strToPosition(position)

    return [
        common.roundDecimal(x + 0.3333) + ":" + common.roundDecimal(y + 0.6666),
        common.roundDecimal(x + 0.6666) + ":" + common.roundDecimal(y + 0.3333),
        common.roundDecimal(x + 0.3333) + ":" + common.roundDecimal(y - 0.3333),
        common.roundDecimal(x - 0.3333) + ":" + common.roundDecimal(y - 0.6666),
        common.roundDecimal(x - 0.6666) + ":" + common.roundDecimal(y - 0.3333),
        common.roundDecimal(x - 0.3333) + ":" + common.roundDecimal(y + 0.3333),
    ]
}

tiles.isWallGap = async (pos) => {
    let neighbours = await tiles.getNeighbours(pos)
    let neighbourPositions = await tiles.getNeighbourPositions(pos)

    for (let index in neighbourPositions) {
        let position = neighbourPositions[index]
        let neighbour = neighbours[index]

        if (!neighbour || position != neighbour.Position)
            neighbours.splice(index, 0, undefined)
    }

    if (tiles.getSafeType(neighbours[0]) == TileType.WALL && tiles.getSafeType(neighbours[1]) == TileType.WALL)
        return true
    else if (tiles.getSafeType(neighbours[2]) == TileType.WALL && tiles.getSafeType(neighbours[3]) == TileType.WALL)
        return true
    else if (tiles.getSafeType(neighbours[4]) == TileType.WALL && tiles.getSafeType(neighbours[5]) == TileType.WALL)
        return true
    else
        return false
}

tiles.isWalkable = (tile, isMilitary) => {
    let type = tiles.getSafeType(tile)

    if (!isMilitary)
        return type == TileType.PATH || type == TileType.GATE
    else
        return type == TileType.PATH || type == TileType.GATE || type == TileType.GRASS
}

function getMin(set){
    let min = 999999
    let minV, index

    for (let i in set) {
        let c = set[i]

        if (c.f < min){
            min = c.f
            minV = c
            index = i
        }
    }

    return [index, minV];
}

function costHeuristic(start, target) {
    let [sx, sy] = common.strToPosition(start)
    let [tx, ty] = common.strToPosition(target)

    let dx = tx - sx
    let dy = ty - sy

    if (Math.sign(dx) != Math.sign(dy))
        return Math.abs(dx) + Math.abs(dy)
    else
        return Math.max(Math.abs(dx), Math.abs(dy))
}
tiles.costHeuristic = costHeuristic

function reconstructPath(start, target, cameFrom) {
    let path = []
    let current = target

    while (current != start) {
        path.unshift(current)
        current = cameFrom[current]
    }

    return path
}

tiles.clearCaches = () => {
    tiles.fastPathCache = {}
    tiles.adjacencyCache = {}
    tiles.fastUnitCollisionCache = {}
    tiles.guardpostsCache = {}
}

tiles.searchFastPathCache = async (position) => {
    let partitionId = common.findPartitionId(position)
    let partitionIndex = common.partitionIndex(position)

    let cache = tiles.fastPathCache[partitionId]

    if (!cache) {
        cache = (await database.getFastPathCache(partitionId)) || []
        tiles.fastPathCache[partitionId] = cache
    }

    return cache[partitionIndex]
}

//Fast cached check to test if a position is walkable
tiles.fastWalkableCheck = async (position, isMilitary, ownerId) => {
    const walkValue = await tiles.searchFastPathCache(position)

    if (!isMilitary)
        return walkValue == 1  //This is a path tile
        
    const unitsObstructing = await tiles.fastUnitCollisionCheck(position)
    let obstruction = false

    //Is there a hostile unit obstructing this path
    if (!ownerId) {
        obstruction = unitsObstructing
    } else {
        if (unitsObstructing) {
            const hostileUnits = unitsObstructing.filter(id => id.split(":")[0] != ownerId)

            if (hostileUnits.length > 0)
                obstruction = true
        }
    }

    //No hostile unit obstructing and this is a path or grass
    return !obstruction && walkValue <= 1 
}

tiles.fastStorageCheck = async (position) => {
    let partitionId = common.findPartitionId(position)
    let partitionIndex = common.partitionIndex(position)

    if (!tiles.fastPathCache[partitionId]) 
        tiles.fastPathCache[partitionId] = await database.getFastPathCache(partitionId)

    return tiles.fastPathCache[partitionId][partitionIndex] == 3
}

tiles.fastAdjacencyCheck = async (position) => {
    let partitionId = common.findPartitionId(position)
    let partitionIndex = common.partitionIndex(position)

    if (!tiles.adjacencyCache[partitionId]) 
        tiles.adjacencyCache[partitionId] = await database.getAdjacencyCache(partitionId)

    return parseInt(tiles.adjacencyCache[partitionId][partitionIndex])
}

tiles.fastUnitCollisionCheck = async (position) => {
    const partitionId = common.findPartitionId(position)
    
    let partitionMilitaryPositions = tiles.fastUnitCollisionCache[partitionId];

    if (!partitionMilitaryPositions) {
        partitionMilitaryPositions = await database.getMilitaryUnitPositionsInPartition(partitionId) || [];

        // update cache
        tiles.fastUnitCollisionCache[partitionId] = partitionMilitaryPositions
    }

    return partitionMilitaryPositions[position]
}

//Commits local changes to the cache so units belonging to the same kingdom can path a bit smarter
tiles.updateFastCollisionCache = async (positionFrom, positionTo, unit) => {
    let partitionId = common.findPartitionId(positionFrom)
    let partitionToId = common.findPartitionId(positionTo)

    if (!tiles.fastUnitCollisionCache[partitionId]) 
        tiles.fastUnitCollisionCache[partitionId] = await database.getMilitaryUnitPositionsInPartition(partitionId) || []

    if (!tiles.fastUnitCollisionCache[partitionToId]) 
        tiles.fastUnitCollisionCache[partitionToId] = await database.getMilitaryUnitPositionsInPartition(partitionToId) || []

    if (!tiles.fastUnitCollisionCache[partitionId][positionFrom])
        tiles.fastUnitCollisionCache[partitionId][positionFrom] = []

    if (!tiles.fastUnitCollisionCache[partitionToId][positionTo])
        tiles.fastUnitCollisionCache[partitionToId][positionTo] = []

    const unitId = unit.OwnerId+':'+unit.Id
    let positionsFrom = tiles.fastUnitCollisionCache[partitionId][positionFrom]
    let positionsTo = tiles.fastUnitCollisionCache[partitionToId][positionTo]
    const fromIndex = positionsFrom.indexOf(unitId)
    
    if (fromIndex != undefined)
        positionsFrom.splice(fromIndex, 1)

    if (!positionsTo.includes(unitId))
        positionsTo.push(unitId)
}

tiles.closestTileToResolveCollision = async (position, targetPosition) => {
    let searchQueue = await tiles.getHighResNeighbourPositions(position, true)

    for (let position of searchQueue) {
        if (!await tiles.fastUnitCollisionCheck(position) && await tiles.fastWalkableCheck(position, true)) {
            let closestDist = Infinity
            let closestTile

            for (let position of searchQueue) {
                let collision = await tiles.fastUnitCollisionCheck(position)
                let distance = costHeuristic(position, targetPosition)
                if (!collision && distance < closestDist) {
                    closestDist = distance
                    closestTile = position
                }
            }

            return closestTile

        } else if (searchQueue.indexOf(position) == -1) {
            searchQueue.push(await tiles.getHighResNeighbourPositions(position))
        }
    }
}

tiles.fastClosestHostileUnitToPosition = async (playerId, position, unitId, ignoreKey) => {  
    
    let cache  = {}
    let [x, y] = common.strToPosition(position)

    let partitions = [
        common.findPartitionId(position),
        common.findPartitionId((x + 20) + ":" + (y + 20)), //TODO: dont use hardcoded partition size
        common.findPartitionId((x + 20) + ":" + (y     )),
        common.findPartitionId((x + 20) + ":" + (y - 20)),
        common.findPartitionId((x     ) + ":" + (y + 20)),
        common.findPartitionId((x     ) + ":" + (y - 20)),
        common.findPartitionId((x - 20) + ":" + (y + 20)),
        common.findPartitionId((x - 20) + ":" + (y     )),
        common.findPartitionId((x - 20) + ":" + (y - 20))]

    for (let partitionId of partitions) {
        if (!tiles.fastUnitCollisionCache[partitionId]) 
            tiles.fastUnitCollisionCache[partitionId] = await database.getMilitaryUnitPositionsInPartition(partitionId)
        
        Object.assign(cache, tiles.fastUnitCollisionCache[partitionId])
    }

    let closestDist = Infinity
    let closestUnit

    for (let unitPosition in cache) {
        let dist = costHeuristic(position, unitPosition)

        if (dist < closestDist) {
            for (let unitKey of cache[unitPosition]) {
                let [ownerId, otherUnitId] = unitKey.split(":")
                
                if (ownerId != playerId && unitKey != ignoreKey) {
                    if (dist != 0 || unitId < otherUnitId) {
                        closestDist = dist
                        closestUnit = unitKey
                        break
                    }
                }
            }
        }
    }

    if (closestDist < 5)
        return closestUnit
}

tiles.findPath = async (start, target, isMilitary, ownerId) => {
    if (!start) {
        console.error("Undefined start tile passed to findPath!")
        return undefined
    }

    if (!target) {
        console.error("Undefined target tile passed to findPath!")
        return undefined
    }

    //start = common.roundPositionString(start)
    //target = common.roundPositionString(target)

    let openSet = []
    let closedSet = new Set()
    let cameFrom = {}
    let gScore = {}
    let iterations = 0
    let iterationLimit = 3000

    openSet.push({p:start, f:0})
    gScore[start] = 0

    while (iterations++ < iterationLimit) {
        let [index, current] = getMin(openSet)
        openSet.splice(index, 1)

        if (!current)
            return
        
        if (current.p == target)
            return reconstructPath(start, target, cameFrom)

        closedSet.add(current.p)

        let neighbours = await tiles.getNeighbourPositions(current.p, isMilitary)

        for (let neighbourPos of neighbours) {
            if (pathfindingBlacklist[neighbourPos])
                continue

            if (closedSet.has(neighbourPos)) 
                continue

            if (!await tiles.fastWalkableCheck(neighbourPos, isMilitary, ownerId) && neighbourPos != target) 
                continue

            if (!gScore[neighbourPos]) 
                gScore[neighbourPos] = Infinity

            let g = gScore[current.p] + 1

            if (!await tiles.fastWalkableCheck(neighbourPos, isMilitary))
                g = g + 2 //Add weight to occupied tile to prefer avoiding it

            if (g < gScore[neighbourPos]) {
                gScore[neighbourPos] = g
                cameFrom[neighbourPos] = current.p
                openSet.push({p:neighbourPos, f:(g + costHeuristic(neighbourPos, target))})
            }
        }
    }

    console.log("Pathfinding hit iteration limit")
}

tiles.findMilitaryPath = (start, target, ownerId) => {
    return tiles.findPath(start, target, true, ownerId)
}

//Searches per unit node instead of per tile
tiles.findHighResMilitaryPath = (start, target) => {

}

tiles.findClosestStorageDist = async (pos) => {
    let searchQueue = []
    let index = 0
    let current = pos
    let distance = {}
    distance[pos] = 0

    while (current) {
        let neighbours = await tiles.getNeighbourPositions(current)
        let dist = distance[current] + 1

        for (let neighbour of neighbours) {
            if (distance[neighbour] && distance[neighbour] < dist)
                continue

            distance[neighbour] = dist

            if (await tiles.fastStorageCheck(neighbour)) //TODO: Check if storage has health?
                return [neighbour, dist]
            else if (await tiles.fastWalkableCheck(neighbour)) {
                searchQueue.push(neighbour)
            }
        }

        current = searchQueue[index++]
    }
}

tiles.findClosestStorage = async (pos) => {
    return (await tiles.findClosestStorageDist(pos))[0]
}

tiles.getNumberOfSimilarAdjacentTiles = async (tile, neighbours) => {
    neighbours = neighbours || await tiles.getNeighbours(tile.Position)
    let n = 0

    for (let neighbour of neighbours)
        if (tiles.getSafeType(neighbour) == tile.Type)
            n++

    return n        
}

tiles.getOutput = async (position) => {
    let tile = await tiles.fromPosString(position)
    return [TileOutputs[tile.Type], 1 + (await tiles.fastAdjacencyCheck(position)/3)]
}

//Nothing is built here
tiles.isEmpty = (tile) => {
    return tiles.getSafeType(tile) == TileType.GRASS
}

//No units are assigned here
tiles.isVacant = (tile) => {
    if (tile && tile.UnitList && tile.UnitList.length > 0)
        return false
    else
        return true
}

tiles.assignWorker = async (pos, unit) => {
    let tile = await tiles.fromPosString(pos)
    if (!tile) return
    tile.UnitList.push(unit.Id)
    database.updateTile(pos, tile)
}

tiles.unassignWorker = async (pos, unit) => {
    let tile = await tiles.fromPosString(pos)

    if (!tile) 
        return

    if (tile.UnitList)
        tile.UnitList = tile.UnitList.filter(id => id != unit.Id)
   
    if (tile.Type == TileType.GRASS) {
        database.deleteTile(pos)
    } else {
        database.updateTile(pos, tile)
    }
}

tiles.getCircularCollection = (pos, radius) => {
    let collection = common.circularPosList(pos, radius)
    return tiles.fromPosList(collection).then(c => c.filter(t => t != undefined))
}

tiles.isProductivityTile = (tile) => {
    let t = tiles.getSafeType(tile)
    return t == TileType.FARM || t == TileType.FORESTRY || t == TileType.MINE
}

tiles.isMilitaryTile = (tile) => {
    return tiles.getSafeType(tile) == TileType.BARRACKS
}

tiles.canAssignWorker = async (pos, unit) => {
    let tile = await tiles.fromPosString(pos)

    //Is there a tile
    if (!tile)
        return false
    
    //Is there already a worker assigned
    if (tile.UnitList.length > 0)
        return false
        
    //Should we take the military route instead
    if (tiles.isMilitaryTile(tile))
        return tiles.canAssignMilitaryWorker(pos, unit)

    //Is the tile owned by the worker owner
    if (unit.OwnerId != tile.OwnerId)
        return false

    //Is it a tile we can assign a worker to
    if (!tiles.isProductivityTile(tile))
        return false

    return true
}

tiles.canAssignMilitaryWorker = async (pos, unit) => {
    let tile = await tiles.fromPosString(pos)
    let type = tiles.getSafeType(tile)

    //Is there already a worker assigned
    if ((tile ? tile.UnitList : []).length > 0)
        return false

    //If it is a barracks we can assign if owned by same owner
    if (type == TileType.BARRACKS && unit.OwnerId == tile.OwnerId)
        return true

    //If it is grass we can assign
    if (type == TileType.GRASS)
        return true
}

tiles.isFragmentationDependant = async (pos, keepPos) => {
    let tile = await tiles.fromPosString(pos)
    
    //If this isn't walkable then it cannot be dependant
    if (!tiles.isWalkable(tile))
        return false

    //Can surrounding tiles still get to the keep if this tile is removed
    let willFragment = false
    pathfindingBlacklist[tile.Position] = true //Simulate removing tile

    for (let neighbour of await tiles.getNeighbours(pos)) {
        if (tiles.getSafeType(neighbour) != TileType.GRASS) {
            let path = await tiles.findPath(neighbour.Position, keepPos)
            if (!path) {
                willFragment = true
                break 
            }
        }
    }

    delete pathfindingBlacklist[tile.Position]

    return willFragment
}

tiles.getRepairCost = async (pos) => {
    let tile = await tiles.fromPosString(pos)
    let cost = TileConstructionCosts[tile.Type]
    let repairAmount = 1 - (tile.Health / tile.MaxHealth)
    let repairCost = {
        Stone: Math.floor(cost.Stone * repairAmount),
        Wood: Math.floor(cost.Wood * repairAmount),
    }

    return repairCost
}

tiles.fastCheckGuardpost = async (id, pos) => {
    if (!tiles.guardpostsCache[id])
        tiles.guardpostsCache[id] = await database.getGuardposts(id)

    return tiles.guardpostsCache[id].includes(pos)
}