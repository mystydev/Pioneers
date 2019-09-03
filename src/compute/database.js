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

database.getTile = (pos) => {
    return redis.hget("tiles", pos).then(data => tiles.tileFromJSON(data, pos))
}

database.getTiles = (tiles) => {
    return redis.hmget("tiles", ...tiles)
}

database.getAllUnits = async () => {
    let data = await redis.hgetall('units')
    let num = 0

    for (let key in data) {
        units.unitFromJSON(data[key])
        num++
    }

    console.log("Loaded", num, "units!")
}

database.getUnit = async (id) => {
    let data = await redis.hget("units", id)
    return units.unitFromJSON(data)
}

database.getUnitProp = async (id, prop) => {
    return redis.hget("unit:"+id, prop)
}

database.setUnitProp = (id, prop, value) => {
    redis.hset("unit"+id, prop, value)
}

database.getUnits = (units) => {
    return redis.hmget("units", ...units)
}

database.getAllStats = async () => {
    let Stats = {}
    let stats = await redis.hgetall('stats')
    let num = 0

    for (let key in stats) {
        Stats[key] = JSON.parse(stats[key])
        num++
    }

    console.log("Loaded", num, "stats!")

    return Stats
}

database.getStat = (id, type) => {
    return redis.hget("stats:"+id, type)
}

database.addStat = (id, type, amount) => {
    redis.hincrby("stats:"+id, type, amount)
}

database.setStat = (id, type, value) => {
    redis.hset("stats:"+id, type, value)
}

database.setStats = (id, stats) => {
    redis.hmset("stats:"+id, stats)
}

database.getAllSettings = async () => {
    let Settings = {}
    let settings = await redis.hgetall('settings')
    let num = 0

    for (let key in settings) {
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
    let spawns = {}
    let data = await redis.hgetall('unitspawns')

    for (let pos in data)
        spawns[pos] = JSON.parse(data[pos])

    return spawns
}

database.getUnitCollection = async (id) => {
    return redis.lrange("unitcollection:"+id, 0, -1)
}

database.getActionQueue = async () => {
    let actions = await redis.lrange("actionQueue", 0, -1)
    redis.ltrim("actionQueue", actions.length, -1)

    return actions
}

database.addPlayer = (id) => {
    redis.rpush("playerlist", id)
}

database.getPlayerList = async () => {
    return redis.lrange("playerlist", 0, -1)
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

database.incrementUnitCount = () => {
    return redis.incr("unitcount")
}

database.pushUnitToCollection = (id, data) => {
    redis.rpush("unitcollection:"+id, data)
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
