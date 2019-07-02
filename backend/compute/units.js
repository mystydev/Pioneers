let units = module.exports = {}
let database = require("./database")
let tiles = require("./tiles")
let userstats = require("./userstats")
let resource = require("./resource")
let common = require("./common")

let Units = {}
let UnitCount
let UnitSpawns
let UnitCollections = []

let UnitType = units.UnitType = {
    NONE:0,
    VILLAGER:1,
    FARMER:2,
    LUMBERJACK:3,
    MINER:4, 
    APPRENTICE:5, 
    SOLDIER:6
};

let UnitState = units.UnitState = {
    IDLE:0, 
    DEAD:1,
    MOVING:2, 
    WORKING:3, 
    RESTING:4, 
    STORING:5, 
    COMBAT:6, 
    LOST:7
};

function Unit(unitId, ownerId, x, y) {
    this.Id = unitId
    this.OwnerId = ownerId
    this.Posx = x
    this.Posy = y
    this.Type = UnitType.VILLAGER
    this.Health = 200
    this.Fatigue = 0
    this.Training = 0
    this.State = UnitState.IDLE
    this.Home = undefined
    this.Work = undefined
    this.Storage = undefined
    this.Target = undefined
    this.Attack = undefined
    this.HeldResource = undefined
    this.ProduceType = undefined
    this.ProduceAmount = undefined
    this.Trip = undefined
    this.TripIndex = 0

    Units[unitId] = this
        
    if (!UnitCollections[ownerId])
        UnitCollections[ownerId] = [unitId]
    else
        UnitCollections[ownerId].push(unitId)
}

units.unitFromJSON = (rawdata) => {
    let data = JSON.parse(rawdata)
    let unit = new Unit(data.Id, data.OwnerId, data.Posx, data.Posy)

    for (let prop in data)
        unit[prop] = data[prop]

    return unit
}

units.load = async () => {
    await database.getAllUnits()
    UnitCount = await database.getUnitCount()
    UnitSpawns = await database.getUnitSpawns()

	if (!UnitCount)
        UnitCount = 1
}

units.newPlayer = (id) => {
    UnitCollections[id] = []
}

units.addResource = (unit, res, amount) => {
    if (!unit.HeldResource || unit.HeldResource.Type != res)
        unit.HeldResource = {Type: res, Amount: amount}
    else
        unit.HeldResource.Amount += amount
}

units.getPosition = (unit) => {
    return unit.Posx + ":" + unit.Posy
}

units.computeTrip = (unit) => {
    let storage = tiles.findClosestStorage(unit.Work)
    unit.Storage = storage

    let homeWorkPath = tiles.findPath(unit.Home, unit.Work)
    let workStoragePath = tiles.findPath(unit.Work, storage)
    let storageHomePath = tiles.findPath(storage, unit.Home)

    if (!homeWorkPath || !workStoragePath || !storageHomePath) {
        unit.State = UnitState.LOST
        return 
    }

    let wholePath = homeWorkPath.concat(workStoragePath, storageHomePath)
    unit.Trip = wholePath
    
    for (index in wholePath) {
        let pos = wholePath[index]

        if (pos == units.getPosition(unit)){
            unit.TripIndex = index
            break;
        }
    }

    let [res, amount] = tiles.getOutput(unit.Work)
    unit.ProduceType = res
    unit.ProduceAmount = amount
}

units.establishState = (unit) => {
    let pos = units.getPosition(unit)
    
    if (unit.Health <= 0)
        return [UnitState.DEAD, pos, unit.Target]

    if (unit.Attack)
        return [UnitState.COMBAT, pos, unit.Target]

    if (unit.Target && pos != unit.Target)
        return [UnitState.MOVING, pos, unit.Target]

    if (pos == unit.Work)
        return [UnitState.WORKING, pos, unit.Work]

    if (pos == unit.Storage && unit.HeldResource)
        return [UnitState.STORING, pos, unit.Target]

    if (unit.Fatigue > 0 && pos == unit.Home)
        return [UnitState.RESTING, pos, unit.Target]
    
    return [UnitState.IDLE, pos, unit.Target]
}

units.processUnit = (unit) => {
    let statChange = undefined
    let [state, pos, target] = units.establishState(unit)
    unit.State = state

    if (!unit.Trip && unit.Work)
        units.computeTrip(unit)

    switch (state) {
        case UnitState.MOVING:
            let trip = unit.Trip
            unit.TripIndex = (unit.TripIndex + 1)%trip.length;
            [unit.Posx, unit.Posy] = common.strToPosition(trip[unit.TripIndex])
            break

        case UnitState.WORKING:
            units.addResource(unit, unit.ProduceType, unit.ProduceAmount)
            unit.Fatigue++

            if (unit.Fatigue >= common.MAX_FATIGUE)
                unit.Target = unit.Storage

            if (!unit.Target)
                unit.State = UnitState.LOST

            break

        case UnitState.RESTING:
            statChange = {
                Id: unit.OwnerId, 
                Type: resource.Type.FOOD, 
                Amount: -common.FATIGUE_RECOVER_RATE * common.FOOD_PER_FATIGUE
            }
            
            unit.Fatigue -= common.FATIGUE_RECOVER_RATE

            if (unit.Fatigue <= 0){
                unit.Fatigue = 0
                unit.Target = unit.Work
            }

            break
        
        case UnitState.STORING:
            statChange = {
                Id: unit.OwnerId, 
                Type: unit.HeldResource.Type, 
                Amount: unit.HeldResource.Amount
            }
            unit.HeldResource = undefined

            if (unit.Fatigue > 0)
                unit.Target = unit.Home

            break
    }

    database.updateUnit(unit.Id, unit)
    return statChange
}

units.processUnits = () => {
    for (id in Units) {
        let unit = Units[id]
        units.processUnit(unit)
    }
}

units.processSpawns = () => {
    for (pos in UnitSpawns) {
		let tile = tiles.fromPosString(pos)

		if (userstats.canAfford(tile.OwnerId, resource.Type.FOOD, common.SPAWN_REQUIRED_FOOD))		
			if (UnitSpawns[pos]++ > common.SPAWN_ATTEMPTS_REQUIRED)
				units.spawn(pos)
	}
}

units.spawn = (pos) => {
    let tile = tiles.fromPosString(pos)
    let id = (UnitCount++).toString()
    let [x, y] = common.strToPosition(pos)

    let unit = new Unit(id, tile.OwnerId, x, y)
    unit.Home = pos

    if (!UnitCollections[unit.OwnerId])
        units.newPlayer(unit.OwnerId)

    Units[id] = unit;
    UnitCollections[unit.OwnerId].push(id)
    userstats.use(unit.OwnerId, resource.Type.FOOD, 100)
    database.updateUnit(id, unit)
    database.updateUnitCount(UnitCount)

    tile.UnitList.push(unit.Id)
    database.updateTile(pos, tile)

    if (tile.UnitList.length >= common.HOUSE_UNIT_NUMBER) {
        delete UnitSpawns[pos]
        database.deleteUnitSpawn(pos)
    } else {
        UnitSpawns[pos] = 0
        database.updateUnitSpawn(pos, UnitSpawns[pos])
    }

    return unit
}

units.fromid = (id) => {
    return Units[id]
}

units.getSpawns = () => {
    return UnitSpawns
}

units.setSpawn = (pos) => {
    UnitSpawns[pos] = 0
    database.updateUnitSpawn(pos, 0)
}

units.getRange = (start, amount) => {
    let data = {}

    for (id = start; id < start + amount; id++)
        data[id] = Units[id]

    return data
}