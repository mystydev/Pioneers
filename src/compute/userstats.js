let common = require("./common")
let database = require("./database")
let tiles = require("./tiles")
let resource = require("./resource")
let performance = require('perf_hooks').performance
let userstats = {}

userstats.load = async () => {
    console.log("Stats would have loaded!")
}

userstats.newPlayer = (id) => {
    stats = {
        Food: 2500,
        Wood: 2500,
        Stone: 2500,
        PlayerId: id,
        Keep: undefined,
        FoodCost: 0,
        WoodCost: 0,
        StoneCost: 0,
        FoodProduced: 0,
        WoodProduced: 0,
        StoneProduced: 0,
    }

    database.setStats(id, stats)
    database.addPlayer(id)
}

userstats.canAfford = async (id, type, amount) => {
    let stat = await database.getStat(id, type)
    return stat > amount
}

userstats.canAffordCost = async (id, cost) => {
    let wood = userstats.canAfford(id, resource.Type.WOOD, cost[resource.Type.WOOD])
    let stone = userstats.canAfford(id, resource.Type.STONE, cost[resource.Type.STONE])

    return (await wood) && (await stone)
}

userstats.use = async (id, type, amount) => {
    await database.addStat(id, type, -amount)
}

userstats.useCost = async (id, cost) => {
    userstats.use(id, resource.Type.WOOD, cost[resource.Type.WOOD])
	userstats.use(id, resource.Type.STONE, cost[resource.Type.STONE])
}

userstats.add = async (id, type, amount) => {
    await database.addStat(id, type, amount)
}

userstats.canBuild = async (id, type) => {
    let requirements = tiles.TileConstructionCosts[type]

    for (res in requirements)
        if (!await userstats.canAfford(id, res, requirements[res]))
            return false
    
    return true
}

userstats.assignKeep = async (id, pos) => {
    await database.setStat(id, "Keep", pos)
}

userstats.hasKeep = async (id) => {
    return await database.getStat(id, "Keep") != ""
}

userstats.getKeep = async (id) => {
    return await database.getStat(id, "Keep")
}

userstats.setPerRoundProduce = (id, food, wood, stone) => {
    database.setStat(id, "FoodProduced", food)
    database.setStat(id, "WoodProduced", wood)
    database.setStat(id, "StoneProduced", stone)
}

userstats.addPerRoundProduce = (id, type, amount) => {
    if (type == resource.Type.FOOD)
        database.addStat(id, "FoodProduced", amount)
    else if (type == resource.Type.WOOD)
        database.addStat(id, "WoodProduced", amount)
    else if (type == resource.Type.STONE)
        database.addStat(id, "StoneProduced", amount)
}

userstats.removePerRoundProduce = (id, type, amount) => {
    userstats.addPerRoundProduce(id, type, -amount)
}

userstats.addTileMaintenance = (id, cost) => {
    database.addStat(id, "WoodCost", cost.Wood)
    database.addStat(id, "StoneCost", cost.Stone)
}

userstats.removeTileMaintenance = (id, cost) => {
    database.addStat(id, "WoodCost", -cost.Wood)
    database.addStat(id, "StoneCost", -cost.Stone)
}

userstats.processMaintenance = async (id) => {
    database.getStat(id, "WoodCost").then(cost => {
        if (cost)
            database.addStat(id, "Wood", -cost)
    })

    database.getStat(id, "StoneCost").then(cost => {
        if (cost)
            database.addStat(id, "Stone", -cost)
    })
}

//Simulated round with no actual unit calculations
userstats.processFastRoundSim = async (id, rounds) => {
    let stats = await database.getStats(id)
    if (stats.Keep) {
        database.addStat(id, "Food", stats.FoodProduced * rounds)
        database.addStat(id, "Wood", (stats.WoodProduced - stats.WoodCost) * rounds)
        database.addStat(id, "Stone", (stats.StoneProduced - stats.StoneCost) * rounds)
    }
}

userstats.setInCombat = (id) => {
    database.setStat(id, "InCombat", Math.floor(Date.now() / 1000))
}

userstats.isInCombat = async (id) => {
    let combatTime = await database.getStat(id, "InCombat")
    return ((Date.now() / 1000) - combatTime) < 10
}

module.exports = userstats