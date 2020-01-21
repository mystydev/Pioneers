let common = module.exports = {}
let tiles = require("./tiles")

//The world is split into many squares with width/height of partitionSize
//These partitions allow for efficient caching of a large number of tiles
const partitionSize = common.partitionSize = 20

common.Actions = {
    NEW_PLAYER:0,
    PLACE_TILE:1,
    SET_WORK:2,
    ATTACK:3,
    DELETE_TILE:4,
    REPAIR_TILE:5,
    DELETE_KINGDOM:6,
    SET_GUARDPOST:7,
};

common.level_requirements = []

common.level_requirements[1] = {Unlocks:[tiles.TileType.FORESTRY]}
common.level_requirements[1]["Population:Farmers"] = 4
common.level_requirements[1]["Built:"+tiles.TileType.HOUSE] = 2
common.level_requirements[1]["Built:"+tiles.TileType.FARM] = 4

common.level_requirements[2] = {Unlocks:[tiles.TileType.MINE]}
common.level_requirements[2]["Population:Lumberjacks"] = 2
common.level_requirements[2]["Built:"+tiles.TileType.HOUSE] = 3
common.level_requirements[2]["Built:"+tiles.TileType.FORESTRY] = 2

common.level_requirements[3] = {}
common.level_requirements[3]["Population:Miners"] = 2

common.level_requirements[4] = {}
common.level_requirements[4]["Population:Miners"] = 4
common.level_requirements[4]["Population:Farmers"] = 6
common.level_requirements[4]["Population:Lumberjacks"] = 4
common.level_requirements[4]["Population:Total"] = 14

common.level_requirements[5] = {Unlocks:[tiles.TileType.STORAGE]}
common.level_requirements[5]["Population:Total"] = 25

common.level_requirements[6] = {Unlocks:[tiles.TileType.BARRACKS]}
common.level_requirements[6]["Population:Total"] = 50
common.level_requirements[6]["Built:"+tiles.TileType.STORAGE] = 3

common.level_requirements[7] = {Unlocks:[tiles.TileType.WALL, tiles.TileType.GATE]}
common.level_requirements[7]["Population:Total"] = 100
common.level_requirements[7]["Population:Soldiers"] = 20

common.level_requirements[8] = {}
common.level_requirements[8]["Population:Total"] = 250
common.level_requirements[8]["Population:Soldiers"] = 50

common.level_requirements[9] = {}
common.level_requirements[9]["Population:Total"] = 500
common.level_requirements[9]["Population:Soldiers"] = 100

common.level_requirements[10] = {}
common.level_requirements[10]["Population:Total"] = 700
common.level_requirements[10]["Population:Soldiers"] = 150

common.level_requirements[11] = {}
common.level_requirements[11]["Population:Total"] = 2000
common.level_requirements[11]["Population:Soldiers"] = 400

common.FULL_SIM_QUOTA = 30 //how many full simulation rounds are required to proceed to lightweight simulation

common.SPAWN_REQUIRED_FOOD = 100      //How much food is required when a unit spawns
common.SPAWN_ATTEMPTS_REQUIRED = 10   //How many rounds to wait before a unit can spawn
common.HOUSE_UNIT_NUMBER = 2          //How many units live in each house
common.MAX_FATIGUE = 10               //A units max fatigue level
common.MAX_STORAGE_DIST = 15          //Maximum distance allowed to a storage tile
common.FOOD_PER_FATIGUE = 0.5         //How much food is require to restore 1 fatigue
common.FATIGUE_RECOVER_RATE = 2       //How much fatigue is recovered per round rested
common.TRAINING_FOR_SOLDIER = 100     //How much training an apprentice needs to become a soldier

common.strToPosition = (pos) => {
    if (!pos) {
        console.error("Undefined position string passed to strToPosition!")
        console.trace()
        return [0, 0]
    }

    let [x, y] = pos.split(":")
    return [parseFloat(x), parseFloat(y)]
}

//Converts x y from axial to world coordinate system
common.xyToWorldPos = (x, y) => {
    return [x * 0.866, y + x * -0.5]
}

common.circularPosList = (pos, radius) => {
    let [posx, posy] = common.strToPosition(pos)
    let list = []

    for (let r = 0; r < radius; r++) {
        for (let i = 0; i < radius; i++) {
            list.push((posx     + i) + ":" + (posy + r    ))
            list.push((posx + r    ) + ":" + (posy + r - i))
            list.push((posx + r - i) + ":" + (posy     - i))
            list.push((posx     - i) + ":" + (posy - r    ))
            list.push((posx - r    ) + ":" + (posy - r + i))
            list.push((posx - r + i) + ":" + (posy     + i))
        }
    }

    return list
}

common.roundPositionString = (position) => {
    let [x, y] = common.strToPosition(position)
    x = Math.floor(x + 0.5)
    y = Math.floor(y + 0.5)
    return x+':'+y
}

common.roundDecimal = (a) => {
    return Math.floor(1000*Math.floor((3*a)+0.5)/3)/1000
}

common.roundDecimalPositionString = (position) => {
    if (!position)
        return ""

	let [x, y] = position.split(":")
	x = common.roundDecimal(parseFloat(x))
	y = common.roundDecimal(parseFloat(y))
    return x+':'+y
}

//Modified Cantor pairing to convert 2d partitions to 1d label
//Integers mapped to naturals to allow cantor to map every integer pair
common.findPartitionId = (pos) => {
    let [x, y] = common.strToPosition(pos)
    x = Math.floor(x / partitionSize)
    y = Math.floor(y / partitionSize)
    x = x >= 0 ? x * 2 : -x * 2 - 1
    y = y >= 0 ? y * 2 : -y * 2 - 1
    return 0.5 * (x + y) * (x + y + 1) + y
}

//Inverse cantor pairing
common.findXYFromPartitionId = (id) => {
    id = parseInt(id)
    let w = Math.floor((Math.sqrt(8 * id + 1) - 1) / 2)
    let t = (w**2 + w) / 2
    let y = id - t
    let x = w - y
    x = x%2 ? (x + 1) / -2 : x = x / 2
    y = y%2 ? (y + 1) / -2 : y = y / 2

    return [x * partitionSize, y * partitionSize]
}

common.getNeighbouringPartitionIds = (partitionId) => {
    const [x, y] = common.findXYFromPartitionId(partitionId)

    return [
        common.findPartitionId((x + partitionSize) + ":" + (y + partitionSize)),
        common.findPartitionId((x + partitionSize) + ":" + (y)),
        common.findPartitionId((x + partitionSize) + ":" + (y - partitionSize)),
        common.findPartitionId((x) + ":" + (y + partitionSize)),
        common.findPartitionId((x) + ":" + (y - partitionSize)),
        common.findPartitionId((x - partitionSize) + ":" + (y + partitionSize)),
        common.findPartitionId((x - partitionSize) + ":" + (y)),
        common.findPartitionId((x - partitionSize) + ":" + (y - partitionSize)),
    ]
}


common.partitionIndex = (position) => {
    let [x, y] = common.strToPosition(position)
    x = Math.floor(x + 0.5)
    y = Math.floor(y + 0.5)
    x = (partitionSize + (x % partitionSize))%partitionSize
    y = (partitionSize + (y % partitionSize))%partitionSize
    return x * partitionSize + y
}

module.exports = common