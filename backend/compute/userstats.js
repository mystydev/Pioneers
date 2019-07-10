let common = require("./common")
let database = require("./database")
let tiles = require("./tiles")
let resource = require("./resource")
let userstats = {}

let Stats

userstats.load = async () => {
    Stats = await database.getAllStats()
}

userstats.newPlayer = (id) => {
    Stats[id] = {
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

    database.updateStats(id, Stats[id])
}

userstats.getStats = (id, type) => {
    return Stats[id][type]
}

userstats.canAfford = (id, type, amount) => {
    return Stats[id][type] > amount
}

userstats.use = (id, type, amount) => {
    Stats[id][type] -= amount
    database.updateStats(id, Stats[id])
}

userstats.add = (id, type, amount) => {
    Stats[id][type] += amount
    database.updateStats(id, Stats[id])
}

userstats.canBuild = (id, type) => {
    let requirements = tiles.TileConstructionCosts[type]

    for (res in requirements)
        if (!userstats.canAfford(id, res, requirements[res]))
            return false
    
    return true
}

userstats.assignKeep = (id, pos) => {
    Stats[id].Keep = pos
    database.updateStats(id, Stats[id])
}

userstats.hasKeep = (id) => {
    return Stats[id].Keep != undefined
}

userstats.setPerRoundProduce = (id, food, wood, stone) => {
    let stats = Stats[id]
    stats.FoodProduced = food
    stats.WoodProduced = wood
    stats.StoneProduced = stone
    database.updateStats(id, stats)
}

userstats.addPerRoundProduce = (id, type, amount) => {
    let stats = Stats[id]

    if (type == resource.Type.FOOD)
        stats.FoodProduced += amount
    else if (type == resource.Type.WOOD)
        woodProduced += amount
    else if (type == resource.Type.STONE)
        stoneProduced += amount

    database.updateStats(id, stats)
}

userstats.removePerRoundProduce = (id, type, amount) => {
    let stats = Stats[id]

    if (type == resource.Type.FOOD)
        stats.FoodProduced -= amount
    else if (type == resource.Type.WOOD)
        woodProduced -= amount
    else if (type == resource.Type.STONE)
        stoneProduced -= amount

    database.updateStats(id, stats)
}

userstats.addTileMaintenance = (id, cost) => {
    let stats = Stats[id]

    stats.WoodCost += cost.Wood
    stats.StoneCost += cost.Stone

    database.updateStats(id, stats)
}

userstats.removeTileMaintenance = (id, cost) => {
    let stats = Stats[id]

    stats.WoodCost -= cost.Wood
    stats.StoneCost -= cost.Stone

    database.updateStats(id, stats)
}

userstats.processMaintenance = () => {
    for (let id in Stats) {
        let stats = Stats[id]

        stats.Wood -= stats.WoodCost
        stats.Stone -= stats.StoneCost

        database.updateStats(id, stats)
    }
}

module.exports = userstats