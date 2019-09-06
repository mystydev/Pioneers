let database = {}
module.exports = database
let common = require("./common")
let units = require("./units")
let Redis = require("ioredis")
let redis

database.connect = () => {
    redis = new Redis.Cluster([{
        port: 6379,
        host: "redis.dev"
    }], {
        scaleReads: "slave"
    })

    return redis
}

database.disconnect = () => {
    redis.disconnect()
}

database.getTile = async (pos) => {
    let [tile] = await database.getTiles([pos])
    return tile
}

database.getTiles = async (positions) => {

    [Types, OwnerIds, Healths, MaxHealths, UnitLists, Positions] = await Promise.all([
        redis.hmget("tile:Type", ...positions),
        redis.hmget("tile:OwnerId", ...positions),
        redis.hmget("tile:Health", ...positions),
        redis.hmget("tile:MaxHealth", ...positions),
        redis.hmget("tile:UnitList", ...positions)])

    let tiles = []
    for (let index in Types) {
        tiles.push({
            Type      : parseInt(Types[index]),
            OwnerId   : OwnerIds[index],
            Health    : Healths[index],
            MaxHealth : MaxHealths[index],
            UnitList  : JSON.parse(UnitLists[index]),
            Position  : positions[index]
        })
    }

    return tiles
}

database.getUnit = async (id) => {
    return await database.getUnitProps(id, units.UnitFields)
}

database.getUnits = async (idList) => {
    if (idList.length == 0) return []

    let data = {}

    for (let prop of units.UnitFields)
        data[prop] = redis.hmget("unit:"+prop, ...idList)

    for (let prop of units.UnitFields)
        data[prop] = await data[prop]

    let unitList = []
    for (let id in idList) {
        let unit = {}
        for (let prop of units.UnitFields)
            unit[prop] = data[prop][id]

        unitList.push(unit)
    }
    
    return Promise.all(unitList)
}

database.updateUnits = async (unitList) => {
    if (unitList.length == 0) return

    let data = {}

    for (let prop of units.UnitFields)
        data[prop] = {}

    for (let unit of unitList)
        for (let prop of units.UnitFields)
            data[prop][unit.Id] = unit[prop]

    for (let prop of units.UnitFields)
        redis.hmset("unit:"+prop, data[prop])
}

database.getUnitsAtPosition = async (pos) => {
    return redis.smembers("unitcache:"+pos)
}

database.getUnitsAtPositions = async (posList) => {
    let cacheList = posList.map(pos => "unitcache:"+pos)
    return redis.sunion(...cacheList)
}

database.getUnitProp = async (id, prop) => {
    return redis.hget("unit:"+prop, id)
}

database.setUnitProp = (id, prop, value) => {
    redis.hset("unit:"+prop, id, value)
}

database.delUnitProp = (id, prop) => {
    redis.hdel("unit:"+prop, id)
}

database.getUnitProps = async (id, props) => {
    let data = {}

    for (let prop of props)
        data[prop] = redis.hget("unit:"+prop, id)
    
    for (let prop of props)
        data[prop] = await data[prop]

    return data
}

database.setUnitProps = async (id, data) => {
    if (data.Position) {
        let oldPos = await database.getUnitProp(id, "Position")
        redis.srem("unitcache:"+oldPos, id)
        redis.sadd("unitcache:"+data.Position, id)
    }

    let processing = []
    for (let prop in data)
        processing.push(redis.hset("unit:"+prop, id, data[prop]))

    return Promise.all(processing)
}

database.increaseUnitProp = (id, prop, amount) => {
    redis.hincrby("unit:"+prop, id, amount)
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
    redis.hincrby("stats:"+id, type, parseInt(amount))
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

database.getUnitSpawns = async (id) => {
    return redis.hgetall("unitspawns:"+id)
}

database.getUnitCollection = async (id) => {
    return redis.lrange("unitcollection:"+id, 0, -1)
}

database.getActionQueue = async (id) => {
    let actions = await redis.lrange("actionQueue:"+id, 0, -1)
    redis.ltrim("actionQueue:"+id, actions.length, -1)

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

database.updateUnitSpawn = (id, pos, count) => {
    redis.hset("unitspawns:"+id, pos, count)
}

database.deleteUnitSpawn = (id, pos) => {
    redis.hdel("unitspawns:"+id, pos)
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
    redis.hset("tile:Type", pos, tile.Type)
    redis.hset("tile:OwnerId", pos, tile.OwnerId)
    redis.hset("tile:Health", pos, tile.Health)
    redis.hset("tile:MaxHealth", pos, tile.MaxHealth)
    redis.hset("tile:UnitList", pos, JSON.stringify(tile.UnitList || []))
}

database.updateTileProp = (prop, pos, value) => {
    redis.hset("tile:"+prop+":"+pos, value)
}

database.deleteTile = (pos) => {
    redis.hdel("tile:Type", pos)
    redis.hdel("tile:OwnerId", pos)
    redis.hdel("tile:Health", pos)
    redis.hdel("tile:MaxHealth", pos)
    redis.hdel("tile:UnitList", pos)
}

database.deleteUnit = async (unitId) => {
    let pos = await database.getUnitProp(unitId, "Position")
    redis.srem("unitcache:"+pos, unitId)
    redis.hset("unit:Health", unitId, 0)
}

database.updateStatus = (time, status) => {
    redis.set("lastprocess", time)
    redis.set("status", status)
}

database.waitForRedis = async () => {
    return await redis.wait(1, 2000)
}
