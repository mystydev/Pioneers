let userstats = {}
module.exports = userstats

let common = require("./common")
let database = require("./database")
let tiles = require("./tiles")
let units = require("./units")
let resource = require("./resource")
let performance = require('perf_hooks').performance

let current_version = "0.29"

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
        Level: 1,
        FoodCost: 0,
        WoodCost: 0,
        StoneCost: 0,
        FoodProduced: 0,
        WoodProduced: 0,
        StoneProduced: 0,
        Version: current_version,
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
    let partitionId = database.findPartitionId(pos)
    database.setPartitionOwner(id, partitionId)
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

userstats.updatePopulation = async (id) => {
    let req = {}
    req[id] = await database.getUnitCollection(id)
    let unitList = await database.getUnits(req)

    let villagers = 0
    let farmers = 0
    let miners = 0
    let lumberjacks = 0
    let soldiers = 0

    for (let unit of unitList) {
        switch (parseInt(unit.Type)) {
            case units.UnitType.VILLAGER:
                villagers++
                break;
            case units.UnitType.FARMER:
                farmers++
                break;
            case units.UnitType.MINER:
                miners++
                break;
            case units.UnitType.LUMBERJACK:
                lumberjacks++
                break;
            case units.UnitType.SOLDIER:
                soldiers++
                break;
        }
    }

    database.setStat(id, "Population:Villagers", villagers)
    database.setStat(id, "Population:Farmers", farmers)
    database.setStat(id, "Population:Miners", miners)
    database.setStat(id, "Population:Lumberjacks", lumberjacks)
    database.setStat(id, "Population:Soldiers", soldiers)
    return database.setStat(id, "Population:Total", unitList.length)
}

userstats.addBuiltBuilding = async (id, buildingType) => {
    database.addStat(id, "Built:"+buildingType, 1)
}

userstats.removeBuiltBuilding = async (id, buildingType) => {
    database.addStat(id, "Built:"+buildingType, -1)
}

userstats.updateBuildingsBuilt = async (id) => {
    let partitions = await database.getPartitionsOwned(id)
    let tiles = await database.getTilesFromPartitions(partitions)
    let builtTiles = {}

    for (let tile of tiles)
        builtTiles[tile.Type] = builtTiles[tile.Type] ? ++builtTiles[tile.Type] : 1

    for (let type in builtTiles)
        database.setStat(id, "Built:"+type, builtTiles[type])
}


//Checks level progression
userstats.checkTrackedStats = async (id) => {
    let level = await database.getStat(id, "Level") || 1
    let requirements = common.level_requirements[level]
    let unfulfilled = false

    for (let requirement in requirements) {
        if (requirement != "Unlocks"){

            let stat = parseInt(await database.getStat(id, requirement)) || 0

            if (stat < requirements[requirement]) {
                unfulfilled = true
                break
            }
        }
    }

    if (!unfulfilled) {
        await database.addStat(id, "Level", 1)
        return await userstats.checkTrackedStats(id)
    }
}

userstats.verifyVersion = async (id) => {
    let version = await database.getStat(id, "Version")

    if (version != current_version) {
        console.log(id, ": outdated stats version("+version+") detected... updating")
        await userstats.recalculate(id)
    }
}

//Used to return stats to a safe state due to a version update or corruption
userstats.recalculate = async (id) => {
    await userstats.updatePopulation(id)
    await userstats.updateBuildingsBuilt(id)
    await userstats.checkTrackedStats(id)
    await database.setStat(id, "Version", current_version)
    console.log(id, ": updated stats to version", current_version)
}

module.exports = userstats