let common = {}

common.Actions = {
    NEW_PLAYER:0,
    PLACE_TILE:1,
    SET_WORK:2,
    ATTACK:3,
    DELETE_TILE:4,
    REPAIR_TILE:5,
};

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
        return [0, 0]
    }

    let [x, y] = pos.split(":")
    return [parseInt(x), parseInt(y)]
}

module.exports = common