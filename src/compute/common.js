let common = {}

common.Actions = {
    NEW_PLAYER:0,
    PLACE_TILE:1,
    SET_WORK:2,
    ATTACK:3,
    DELETE_TILE:4,
    REPAIR_TILE:5,
};

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