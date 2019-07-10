let tiles = module.exports = {}
let database = require("./database")
let common = require("./common")
let resource = require("./resource")
let userstats = require("./userstats")
let units = require("./units")

let Tiles = {}

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
    GATE:10
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

function Tile(type, id, pos, unitlist) {
    this.Type = type
    this.OwnerId = id
    this.Health = defaults[type].Health
    this.UnitList = unitlist || []

    Tiles[pos] = this
    database.updateTile(pos, this)

    if (type == TileType.HOUSE && this.UnitList.length < common.HOUSE_UNIT_NUMBER) {
        units.setSpawn(pos)
    }

    if (type == TileType.KEEP) {
        let neighbours = tiles.getNeighbours(pos)

        for (p of neighbours)
            new Tile(TileType.PATH, id, p)

        userstats.assignKeep(id, pos)
    }
}

tiles.Tile = Tile

tiles.deleteTile = (pos) => {
    delete Tiles[pos]
    units.removeSpawn(pos)
    database.deleteTile(pos)
}

tiles.tileFromJSON = (rawdata, pos) => {
    let data = JSON.parse(rawdata)
    let tile = new Tile(data.Type, data.OwnerId, pos, data.UnitList)

    for (let prop in data)
        tile[prop] = data[prop]

    database.updateTile(pos, tile)

    return tile
}

tiles.load = async () => {
    await database.getAllTiles()
}

tiles.fromPosString = (pos) => {
    return Tiles[pos]
}

tiles.fromCoords = (posx, posy) => {
    return Tiles[posx + ":" + posy]
}

tiles.getSafeType = (pos) => {
    let tile = Tiles[pos]
    return tile ? tile.Type : TileType.GRASS
}

tiles.getNeighbours = (pos) => {
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

tiles.isWallGap = (pos) => {
    let neighbours = tiles.getNeighbours(pos)

    if (tiles.getSafeType(neighbours[0]) == TileType.WALL && tiles.getSafeType(neighbours[1]) == TileType.WALL)
        return true
    else if (tiles.getSafeType(neighbours[2]) == TileType.WALL && tiles.getSafeType(neighbours[3]) == TileType.WALL)
        return true
    else if (tiles.getSafeType(neighbours[4]) == TileType.WALL && tiles.getSafeType(neighbours[5]) == TileType.WALL)
        return true
    else
        return false
}

tiles.isWalkable = (pos) => {
    return tiles.getSafeType(pos) == TileType.PATH
}

function getMin(set){
    let min = 999999
    let minV, index

    for (i in set) {
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

tiles.findPath = (start, target) => {
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

        closedSet.add(current)

        let neighbours = tiles.getNeighbours(current.p)

        for (let neighbour of neighbours) {
            if (closedSet.has(neighbour)) continue
            if (!tiles.isWalkable(neighbour) && neighbour != target) continue
            if (!gScore[neighbour]) gScore[neighbour] = Infinity

            let g = gScore[current.p] + 1

            if (g < gScore[neighbour]) {
                gScore[neighbour] = g
                cameFrom[neighbour] = current.p
                openSet.push({p:neighbour, f:(g + costHeuristic(neighbour, target))})
            }
        }
    }
}

tiles.findClosestStorage = (pos) => {
    let searchQueue = [pos]
    let current
    let index = 0
    let distance = {}
    distance[pos] = 0

    while (current = searchQueue[index++]) {
        let neighbours = tiles.getNeighbours(current)
        let dist = distance[current] + 1

        for (let neighbour of neighbours) {
            if (distance[neighbour] && distance[neighbour] < dist)
                continue

            distance[neighbour] = dist
            let type = tiles.getSafeType(neighbour)

            if (type == TileType.STORAGE || type == TileType.KEEP)
                return neighbour
            else
                searchQueue.push(neighbour)
        }
    }
}

tiles.getOutput = (pos) => {
    let tile = tiles.fromPosString(pos)
    let neighbours = tiles.getNeighbours(pos)

    let produce = 6

    for (n of neighbours)
        if (tiles.getSafeType(n) == tile.Type)
            produce++

    return [TileOutputs[tile.Type], produce]
}

tiles.isEmpty = (pos) => {
    return tiles.getSafeType(pos) == TileType.GRASS
}

tiles.assignWorker = (pos, unit) => {
    let tile = tiles.fromPosString(pos)
    tile.UnitList.push(unit.Id)
    database.updateTile(pos, tile)
}

tiles.unassignWorker = (pos, unit) => {
    let tile = tiles.fromPosString(pos)
    tile.UnitList = tile.UnitList.filter(id => id != unit.Id)
    database.updateTile(pos, tile)
}

tiles.getCircularCollection = (pos, radius) => {
    let [posx, posy] = common.strToPosition(pos)
    let collection = []

    for (let r = 0; r < radius; r++) {
        for (let i = 0; i < radius; i++) {
            collection.push(tiles.fromCoords(posx     + i, posy + r    ))
            collection.push(tiles.fromCoords(posx + r    , posy + r - i))
            collection.push(tiles.fromCoords(posx + r - i, posy     - i))
            collection.push(tiles.fromCoords(posx     - i, posy - r    ))
            collection.push(tiles.fromCoords(posx - r    , posy - r + i))
            collection.push(tiles.fromCoords(posx - r + i, posy     + i))
        }
    }

    return collection.filter(t => t != undefined)
}

tiles.isProductivityTile = (pos) => {
    let t = tiles.getSafeType(pos)
    return t == TileType.FARM || t == TileType.FORESTRY || t == TileType.MINE
}

tiles.canAssignWorker = (pos, unit) => {
    let tile = tiles.fromPosString(pos)

    //Is there a tile
    if (!tile)
        return false

    //Is it a tile we can assign a worker to
    if (!tiles.isProductivityTile(pos))
        return false
    
    //Is there already a worker assigned
    if (tile.UnitList.length > 0)
        return false
        
    //Is the tile owned by the worker owner
    if (unit.OwnerId != tile.OwnerId)
        return false

    return true
}