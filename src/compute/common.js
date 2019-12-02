let common = module.exports = {}
let tiles = require("./tiles")

common.Actions = {
    NEW_PLAYER:0,
    PLACE_TILE:1,
    SET_WORK:2,
    ATTACK:3,
    DELETE_TILE:4,
    REPAIR_TILE:5,
};

common.level_requirements = []

common.level_requirements[1] = {Unlocks:[tiles.TileType.FORESTRY, tiles.TileType.MINE]}
common.level_requirements[1]["Population:Farmers"] = 4
common.level_requirements[1]["Built:"+tiles.TileType.HOUSE] = 2
common.level_requirements[1]["Built:"+tiles.TileType.FARM] = 4

common.level_requirements[2] = {}
common.level_requirements[2]["Population:Total"] = 10
common.level_requirements[2]["Built:"+tiles.TileType.HOUSE] = 5
common.level_requirements[2]["Built:"+tiles.TileType.FARM] = 6
common.level_requirements[2]["Built:"+tiles.TileType.MINE] = 2
common.level_requirements[2]["Built:"+tiles.TileType.FORESTRY] = 2

common.level_requirements[3] = {Unlocks:[tiles.TileType.STORAGE]}
common.level_requirements[3]["Population:Total"] = 20
common.level_requirements[3]["Built:"+tiles.TileType.HOUSE] = 10

common.level_requirements[4] = {Unlocks:[tiles.TileType.BARRACKS]}
common.level_requirements[4]["Population:Total"] = 40
common.level_requirements[4]["Built:"+tiles.TileType.STORAGE] = 1

common.FULL_SIM_QUOTA = 30 //how many full simulation rounds are required to proceed to lightweight simulation

common.SPAWN_REQUIRED_FOOD = 100
common.SPAWN_ATTEMPTS_REQUIRED = 10
common.HOUSE_UNIT_NUMBER = 2
common.MAX_FATIGUE = 10
common.MAX_STORAGE_DIST = 15
common.FOOD_PER_FATIGUE = 2
common.FATIGUE_RECOVER_RATE = 5
common.LAND_CLAIM_RADIUS = 30
common.TRAINING_FOR_SOLDIER = 100

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