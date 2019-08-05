let database = {}
module.exports = database
let Redis = require("ioredis")
let units = require("./units")
let tiles = require("./tiles")

let redis

database.connect = () => {
    redis = new Redis.Cluster([{
        port: 6379,
        host: "redis.dev"
    }])
}

database.disconnect = () => {
    redis.disconnect()
}

database.getAllTiles = async () => {
    let data = await redis.hgetall("tiles")
    let num = 0

    for (key in data) {
        tiles.tileFromJSON(data[key], key)
        num++
    }

    console.log("Loaded", num, "tiles!")
}

database.getTile = async (pos) => {
    let data = await redis.hget("tiles", pos)
    
    if (data)
        return tiles.tileFromJSON(data, pos)
    else
        return undefined
}

database.getAllUnits = async () => {
    let data = await redis.hgetall('units')
    let num = 0

    for (key in data) {
        units.unitFromJSON(data[key])
        num++
    }

    console.log("Loaded", num, "units!")
}

database.getUnit = async (id) => {
    let data = await redis.hget("units", id)
    return units.unitFromJSON(data)
}

database.getAllStats = async () => {
    let Stats = {}
    let stats = await redis.hgetall('stats')
    let num = 0

    for (key in stats) {
        Stats[key] = JSON.parse(stats[key])
        num++
    }

    console.log("Loaded", num, "stats!")

    return Stats
}

database.getAllSettings = async () => {
    let Settings = {}
    let settings = await redis.hgetall('settings')
    let num = 0

    for (key in settings) {
        Settings[key] = JSON.parse(settings[key])
        num++
    }

    console.log("Loaded", num, "user settings!")

    return Settings
}

database.getUnitCount = async () => {
    return await redis.get("unitcount")
}

database.getUnitSpawns = async () => {
    let Spawns = {}
    let spawns = await redis.hgetall('unitspawns')

    num = 0
    for (pos in spawns) {
        Spawns[pos] = JSON.parse(spawns[pos])
        num++
    }
    console.log("Loaded", num, "spawns!")

    return Spawns
}

database.getActionQueue = async () => {
    let actions = await redis.lrange("actionQueue", 0, -1)
    redis.ltrim("actionQueue", actions.length, -1)

    return actions
}

database.updateStats = (id, stats) => {
    redis.hset("stats", id, JSON.stringify(stats))
}

database.updateSettings = (id, settings) => {
    redis.hset("settings", id, JSON.stringify(settings))
}

database.updateUnit = (id, unit) => {
    redis.hset("units", id, JSON.stringify(unit))
}

database.updateUnitSpawn = (pos, count) => {
    redis.hset("unitspawns", pos, count)
}

database.deleteUnitSpawn = (pos) => {
    redis.hdel("unitspawns", pos)
}

database.updateUnitCount = (count) => {
    redis.set("unitcount", count)
}

database.updateTile = (pos, tile) => {
    redis.hset("tiles", pos, JSON.stringify(tile))
}

database.deleteTile = (pos) => {
    redis.hdel("tiles", pos)
}

database.deleteUnit = (unitId) => {
    redis.hdel("units", unitId)
}

database.updateStatus = (time, status) => {
    redis.set("lastprocess", time)
    redis.set("status", status)
}
