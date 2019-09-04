let tiles = module.exports = {}
let performance = require('perf_hooks').performance
let database = require("./database")
let common = require("./common")
let resource = require("./resource")
let userstats = require("./userstats")
let units = require("./units")

let TileType = tiles.TileType = {
    DESTROYED:-1,
    GRASS:0,
    KEEP:1,
    PATH:2,
    HOUSE:3,
    FARM:4,
    MINE:5,
    FORESTRY:6,
    STORAGE:7,
    BARRACKS:8,
    WALL:9,
    GATE:10,
    OTHERPLAYER:1000,
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
TileConstructionCosts[TileType.HOUSE]    = {Stone:100,   Wood:100};
TileConstructionCosts[TileType.FARM]     = {Stone:75,    Wood:75};
TileConstructionCosts[TileType.MINE]     = {Stone:0,     Wood:150};
TileConstructionCosts[TileType.FORESTRY] = {Stone:150,   Wood:0};
TileConstructionCosts[TileType.STORAGE]  = {Stone:500,   Wood:500};
TileConstructionCosts[TileType.BARRACKS] = {Stone:500,   Wood:300};
TileConstructionCosts[TileType.WALL]     = {Stone:1000,  Wood:1000};
TileConstructionCosts[TileType.GATE]     = {Stone:1000,  Wood:1500};

let TileMaintenanceCosts = tiles.TileMaintenanceCosts = {}
TileMaintenanceCosts[TileType.KEEP]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.PATH]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.HOUSE]    = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.FARM]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.MINE]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.FORESTRY] = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.STORAGE]  = {Stone:1,     Wood:1};
TileMaintenanceCosts[TileType.BARRACKS] = {Stone:2,     Wood:2};
TileMaintenanceCosts[TileType.WALL]     = {Stone:3,     Wood:3};
TileMaintenanceCosts[TileType.GATE]     = {Stone:3,     Wood:3};

let TileOutputs = {}
TileOutputs[TileType.FARM]     = resource.Type.FOOD
TileOutputs[TileType.FORESTRY] = resource.Type.WOOD
TileOutputs[TileType.MINE]     = resource.Type.STONE

//Tiles to temporarily ignore during pathfinding
let pathfindingBlacklist = {}

function Tile(type, id, pos, unitlist) {
    this.Type = type
    this.OwnerId = id
    this.Health = defaults[type].Health
    this.MaxHealth = defaults[type].Health
    this.UnitList = unitlist || []
    this.Position = pos
}

//A tile which will update database values on creation
//Should only be used when a new tile is made, not a representation of an exisiting tile
function AuthoritativeTile(type, id, pos, unitlist) {
    this.Type = type
    this.OwnerId = id
    this.Health = defaults[type].Health
    this.MaxHealth = defaults[type].Health
    this.UnitList = unitlist || []
    this.Position = pos

    database.updateTile(pos, this)

    if (type == TileType.HOUSE && this.UnitList.length < common.HOUSE_UNIT_NUMBER) {
        units.setSpawn(pos)
    }

    if (type == TileType.KEEP) {
        let neighbours = tiles.getNeighbourPositions(pos)

        for (let p of neighbours)
            new AuthoritativeTile(TileType.PATH, id, p)

        userstats.assignKeep(id, pos)
    }
}

tiles.Tile = Tile
tiles.AuthoritativeTile = AuthoritativeTile

tiles.deleteTile = (pos) => {
    units.removeSpawn(pos)
    database.deleteTile(pos)
}

tiles.tileFromJSON = (rawdata, pos) => {
    if (!rawdata)
        return undefined 

    let data = JSON.parse(rawdata)
    let tile = new Tile(data.Type, data.OwnerId, pos, data.UnitList)

    for (let prop in data)
        tile[prop] = data[prop]

    database.updateTile(pos, tile)

    return tile
}

tiles.load = async () => {
    console.log("Tiles would have loaded!")
}

tiles.fromPosString = (pos) => {
    return database.getTile(pos)
}

tiles.fromPosList = async (list) => {
    let tileList = []
    
    return database.getTiles(list).then(tileData => {
        for (let tile of tileData)
            tileList.push(tiles.tileFromJSON(tile))

        return tileList
    })
}

tiles.fromCoords = (posx, posy) => {
    return database.getTile(posx + ":" + posy)
}

tiles.dbFromCoords = async (posx, posy) => {
    return await database.getTile(posx + ":" + posy) 
}

tiles.getSafeType = (tile) => {
    return tile ? tile.Type : TileType.GRASS
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

    return tiles.fromPosList(tiles.getNeighbourPositions(pos))
}

tiles.getNeighbourPositions = (pos) => {
    var [x, y] = common.strToPosition(pos)

    return [
        (x    ) + ":" + (y + 1),
        (x    ) + ":" + (y - 1),
        (x + 1) + ":" + (y + 1),
        (x - 1) + ":" + (y - 1),
        (x + 1) + ":" + (y    ),
        (x - 1) + ":" + (y    )
    ]
}

tiles.isWallGap = async (pos) => {
    let neighbours = await tiles.getNeighbours(pos)

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

function reconstructPath(start, target, cameFrom) {
    let path = []
    let current = target

    while (current != start) {
        path.unshift(current)
        current = cameFrom[current]
    }

    return path
}

tiles.findPath = async (start, target, isMilitary) => {
    if (!start) {
        console.error("Undefined start tile passed to findPath!")
        return undefined
    }

    if (!target) {
        console.error("Undefined target tile passed to findPath!")
        return undefined
    }

    let openSet = []
    let closedSet = new Set()
    let cameFrom = {}
    let gScore = {}
    let iterations = 0
    let iterationLimit = 1000

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

        let neighbours = await tiles.getNeighbours(current.p)

        for (let neighbour of neighbours) {
            if (!neighbour) continue
            let neighbourPos = neighbour.Position
            if (pathfindingBlacklist[neighbourPos]) continue
            if (closedSet.has(neighbourPos)) continue
            if (!tiles.isWalkable(neighbour, isMilitary) && neighbourPos != target) continue
            if (!gScore[neighbourPos]) gScore[neighbourPos] = Infinity

            let g = gScore[current.p] + 1

            if (g < gScore[neighbourPos]) {
                gScore[neighbourPos] = g
                cameFrom[neighbourPos] = current.p
                openSet.push({p:neighbourPos, f:(g + costHeuristic(neighbourPos, target))})
            }
        }
    }
}

tiles.findMilitaryPath = (start, target) => {
    return tiles.findPath(start, target, true)
}

tiles.findClosestStorage = async (pos) => {
    let tile = await tiles.fromPosString(pos)
    let searchQueue = [tile]
    let index = 0
    let current = true
    let distance = {}
    distance[pos] = 0

    while (current) {
        current = searchQueue[index++]
        let neighbours = await tiles.getNeighbours(current.Position)
        let dist = distance[current] + 1

        for (let neighbour of neighbours) {
            if (distance[neighbour] && distance[neighbour] < dist)
                continue

            distance[neighbour] = dist

            if (tiles.isStorageTile(neighbour) && neighbour.Health > 0)
                return neighbour.Position
            else if (tiles.isWalkable(neighbour)) {
                searchQueue.push(neighbour)
            }
        }
    }
}

tiles.getOutput = async (pos) => {
    let tile = await tiles.fromPosString(pos)
    let neighbours = await tiles.getNeighbours(pos)
    let produce = 6

    for (let n of neighbours) {
        if (tiles.getSafeType(n) == tile.Type)
            produce++
    }

    return [TileOutputs[tile.Type], produce]
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
    let tile = await tiles.fromPosString(pos) || new Tile(TileType.GRASS, unit.OwnerId, pos)
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
    let [posx, posy] = common.strToPosition(pos)
    let collection = []

    for (let r = 0; r < radius; r++) {
        for (let i = 0; i < radius; i++) {
            collection.push((posx     + i) + ":" + (posy + r    ))
            collection.push((posx + r    ) + ":" + (posy + r - i))
            collection.push((posx + r - i) + ":" + (posy     - i))
            collection.push((posx     - i) + ":" + (posy - r    ))
            collection.push((posx - r    ) + ":" + (posy - r + i))
            collection.push((posx - r + i) + ":" + (posy     + i))
        }
    }

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