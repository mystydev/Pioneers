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

database.getAllUnits = async () => {
    let data = await redis.hgetall('units')
    let num = 0

    for (key in data) {
        units.unitFromJSON(data[key])
        num++
    }

    console.log("Loaded", num, "units!")
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

database.updateStatus = (time, status) => {
    redis.set("lastprocess", time)
    redis.set("status", status)
}
