let common = module.exports = {}
let tiles = require("./tiles")

common.Actions = {
    NEW_PLAYER:0,
    PLACE_TILE:1,
    SET_WORK:2,
    ATTACK:3,
    DELETE_TILE:4,
    REPAIR_TILE:5,
    DELETE_KINGDOM:6,
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
    return [parseInt(x), parseInt(y)]
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

module.exports = common