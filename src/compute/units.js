let units = module.exports = {}
let database = require("./database")
let tiles = require("./tiles")
let userstats = require("./userstats")
let resource = require("./resource")
let common = require("./common")

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
    TRAINING:6,
    GUARDING:7, 
    COMBAT:8,
    LOST:9
};

let MilitaryWorkType = units.MilitaryWorkType = {
    BARRACKS:0,
    GUARDPOST:1,
    ATTACKPOST:2
}

function Unit(unitId, ownerId, x, y) {
    this.Id = unitId
    this.OwnerId = ownerId
    this.Posx = x
    this.Posy = y
    this.Type = UnitType.VILLAGER
    this.Health = 200
    this.Fatigue = 0
    this.Training = 0
    this.MaxTraining = common.TRAINING_FOR_SOLDIER
    this.State = UnitState.IDLE
    this.Home = undefined
    this.Work = undefined
    this.Storage = undefined
    this.Target = undefined
    this.Attack = undefined
    this.UnderAttack = undefined
    this.HeldResource = undefined
    this.ProduceType = undefined
    this.ProduceAmount = undefined
    this.Trip = undefined
    this.TripIndex = 0
    this.TempPath = undefined
    this.TempPathIndex = undefined
    this.MilitaryWorkType = undefined

    /*if (!UnitCollections[ownerId])
        UnitCollections[ownerId] = [unitId]
    else
        UnitCollections[ownerId].push(unitId)*/
}

units.unitFromJSON = (rawdata) => {
    let data = JSON.parse(rawdata)
    let unit = new Unit(data.Id, data.OwnerId, data.Posx, data.Posy)

    for (let prop in data)
        unit[prop] = data[prop]

    if (unit.Health <= 0)
        return units.kill(unit)

    return unit
}

units.load = async () => {
    /*await database.getAllUnits()
    UnitCount = await database.getUnitCount()
    UnitSpawns = await database.getUnitSpawns()

	if (!UnitCount)
        UnitCount = 1*/

    console.log("Units would have loaded!")    
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

units.computeTempSafetyPath = (unit) => {
    let unitPos = units.getPosition(unit)

    unit.TempPath = tiles.findPath(unitPos, unit.Home)
    unit.TripIndex = -1
    unit.TempPathIndex = -1

    if (!unit.TempPath) {
        console.log("Failed to create temp path")
        unit.State = UnitState.LOST
        return
    }
}

units.computeTrip = async (unit) => {
    if (!unit.Work || await tiles.fromPosString(unit.Work).Health <= 0){
        console.log("Early trip exit")
        units.computeTempSafetyPath(unit)
        unit.Target = unit.Home
        delete unit.Trip
        database.updateUnit(unit.Id, unit)

        return
    }

    let storage = await tiles.findClosestStorage(unit.Work)
    let homeWorkPath = await tiles.findPath(unit.Home, unit.Work)
    let workStoragePath = await tiles.findPath(unit.Work, storage.Position)
    let storageHomePath = await tiles.findPath(storage.Position, unit.Home)

    if (!homeWorkPath || !workStoragePath || !storageHomePath) {
        units.unassignWork(unit)
        units.computeTempSafetyPath(unit)
        return 
    }

    let wholePath = homeWorkPath.concat(workStoragePath, storageHomePath)
    let pos = units.getPosition(unit)
    let [res, amount] = await tiles.getOutput(unit.Work)

    //-1 to start just before path
    if (unit.Target == unit.Work) {
        unit.TripIndex = homeWorkPath.indexOf(pos) || -1
    } else if (unit.Target == storage.Position) {
        unit.TripIndex = homeWorkPath.length + (workStoragePath.indexOf(pos) || -1)
    } else if (unit.Target == unit.Home) {
        unit.TripIndex = homeWorkPath.length + workStoragePath.length + (storageHomePath.indexOf(pos) || -1)
    } else {
        unit.TripIndex = -1
    }

    let unitPos = units.getPosition(unit)
    if (unitPos != wholePath[unit.TripIndex] && unitPos != unit.Home) {
        console.log("Computing safety path")
        units.computeTempSafetyPath(unit)
    } else {
        delete unit.TempPath
        delete unit.TempPathIndex
    }

    unit.Storage = storage.Position
    unit.Trip = wholePath
    unit.ProduceType = res
    unit.ProduceAmount = amount

    database.updateUnit(unit.Id, unit)
}

units.computeMilitaryTrip = async (unit) => {
    let pos = units.getPosition(unit)
    let workTile = await tiles.fromPosString(unit.Work)
    let workType = tiles.getSafeType(workTile)

    unit.Trip = tiles.findPath(pos, unit.Target, true)
    unit.Storage = undefined
    unit.ProduceType = undefined
    unit.ProduceAmount = undefined
    unit.TripIndex = -1

    if (!unit.Trip) {
        unit.State = UnitState.LOST
        database.updateUnit(unit.Id, unit)
        return
    }

    if (unit.Attack == unit.Target) {
        unit.MilitaryWorkType = MilitaryWorkType.ATTACKPOST //Messy?
        unit.Target = unit.Trip[unit.Trip.length - 2]
        unit.Work = unit.Target
        unit.Trip.pop()
    } else if (workType == tiles.TileType.BARRACKS) {
        unit.MilitaryWorkType = MilitaryWorkType.BARRACKS
    } else if (workType == tiles.TileType.GRASS) {
        unit.MilitaryWorkType = MilitaryWorkType.GUARDPOST
    }

    database.updateUnit(unit.Id, unit)
}

units.isMilitary = (unit) => {
    return unit.Type == UnitType.APPRENTICE || unit.Type == UnitType.SOLDIER
}

units.establishState = (unit) => {
    let pos = units.getPosition(unit)

    if (unit.Health <= 0)
        return UnitState.DEAD

    if (unit.Target && pos != unit.Target)
        return UnitState.MOVING

    if (pos == unit.Work)
        return UnitState.WORKING

    if (pos == unit.Storage && unit.HeldResource)
        return UnitState.STORING

    if (unit.Fatigue > 0 && pos == unit.Home)
        return UnitState.RESTING

    if (!unit.Work)
        return UnitState.IDLE
    
    return UnitState.LOST
}

units.establishMiliatryState = (unit) => {
    let pos = units.getPosition(unit)

    if (unit.Health <= 0)
        return UnitState.DEAD

    if (unit.Target && pos != unit.Target)
        return UnitState.MOVING

    if (unit.Attack)
        return UnitState.COMBAT

    if (unit.MilitaryWorkType == MilitaryWorkType.BARRACKS)
        return UnitState.TRAINING

    if (unit.MilitaryWorkType == MilitaryWorkType.GUARDPOST)
        return UnitState.GUARDING

    if (unit.Fatigue > 0 && pos == unit.Home)
        return UnitState.RESTING
    
    if (!unit.Work)
        return UnitState.IDLE

    return UnitState.LOST
}

units.processUnit = async (unit) => {
    if (units.isMilitary(unit))
        return await units.processMilitaryUnit(unit)

    let changes = {}
    let state = units.establishState(unit)
    unit.State = state

    if (unit.State != UnitState.MOVING && !unit.Trip && unit.Work) {
        unit.State = UnitState.LOST
        database.updateUnit(unit.Id, unit)
        return {}
    }

    switch (state) {
        case UnitState.MOVING:
            /*if (unit.TempPathIndex != undefined && unit.TempPath) {
                if (unit.TempPathIndex++ >= unit.TempPath.length-1) {
                    delete unit.TempPathIndex
                    delete unit.TempPath
                    unit.Target = unit.Work
                } else {
                    let pos = unit.TempPath[unit.TempPathIndex];
                    [unit.Posx, unit.Posy] = common.strToPosition(pos)
                }
            } else {
                let trip = unit.Trip
                if (trip) {
                    unit.TripIndex = (unit.TripIndex + 1)%trip.length;
                    [unit.Posx, unit.Posy] = common.strToPosition(trip[unit.TripIndex])
                }
            }
            */

            let path = await tiles.findPath(units.getPosition(unit), unit.Target);
            [unit.Posx, unit.Posy] = common.strToPosition(path[0])
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
            changes.Stats = {
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
            changes.Stats = {
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
    return changes
}

units.processMilitaryUnit = async (unit) => {
    let changes = {}
    let state = units.establishMiliatryState(unit)
    unit.State = state

    switch (state) {
        case UnitState.MOVING:
            let trip = unit.Trip
            if (!trip) {
                unit.State = UnitState.LOST
                break
            }

            let nextIndex = Math.min(unit.TripIndex + 1, trip.length - 1) || 0;
            let nextPos = trip[nextIndex];
            let [nextX, nextY] = common.strToPosition(nextPos);
            let tile = await tiles.dbFromCoords(nextX, nextY);
            
            if (tile && nextPos != unit.Work && tile.UnitList.length > 0) {
                unit.Target = units.getPosition(unit)
                unit.Attack = nextPos
            } else {
                unit.TripIndex = nextIndex;
                [unit.Posx, unit.Posy] = [nextX, nextY];
            }
            break

        case UnitState.TRAINING:
            unit.Training++

            if (unit.Training >= common.TRAINING_FOR_SOLDIER){
                unit.Type = UnitType.SOLDIER
                unit.Training = 0
                unit.MaxTraining = 10000
            }

            if (!unit.Target)
                unit.State = UnitState.LOST

            break

        case UnitState.COMBAT:
            changes.Damage = {
                Pos: unit.Attack,
                UnitId: unit.Id,
                Health: 10,
            }
            changes.InCombat = unit.OwnerId
            break
    }

    database.updateUnit(unit.Id, unit)
    return changes
}

units.processUnits = async () => {
    for (let id in Units) {
        let unit = Units[id]
        await units.processUnit(unit)
    }
}

units.processSpawns = async () => {
    let UnitSpawns = await database.getUnitSpawns()

    for (let pos in UnitSpawns) {
		let tile = await tiles.fromPosString(pos)

        if (await userstats.canAfford(tile.OwnerId, resource.Type.FOOD, common.SPAWN_REQUIRED_FOOD)) {  
			if (UnitSpawns[pos] > common.SPAWN_ATTEMPTS_REQUIRED)
                units.spawn(pos)
            else
                database.updateUnitSpawn(pos, UnitSpawns[pos] + 1)
        }
    }
}

units.spawn = async (pos) => {
    let tile = await tiles.fromPosString(pos)
    let id = (await database.incrementUnitCount()).toString()
    let [x, y] = common.strToPosition(pos)

    let unit = new Unit(id, tile.OwnerId, x, y)
    unit.Home = pos

    database.pushUnitToCollection(unit.OwnerId, id)
    userstats.use(unit.OwnerId, resource.Type.FOOD, 100)
    database.updateUnit(id, unit)

    tile.UnitList.push(unit.Id)
    database.updateTile(pos, tile)

    if (tile.UnitList.length >= common.HOUSE_UNIT_NUMBER) {
        database.deleteUnitSpawn(pos)
    } else {
        database.updateUnitSpawn(pos, 0)
    }

    return unit
}

units.getUnitCount = async () => {
    return database.getUnitCount()
}

//recompute cached unit info on civ changes (ie path might change due to tile placement)
units.recomputeCiv = async (id) => {
    console.log("recomputing", id)

    let UnitCollection = await database.getUnitCollection(id)
    console.log("Unit collection is:", UnitCollection)
    if (!UnitCollection)
        return

    let foodProduced = 0
    let woodProduced = 0
    let stoneProduced = 0

    for (let unitId of UnitCollection) {
        let unit = Units[unitId]
        units.computeTrip(unit)

        if (unit.Trip) {
            if (unit.ProduceType == resource.Type.FOOD)
                foodProduced += unit.ProduceAmount / unit.Trip.length
            else if (unit.ProduceType == resource.Type.WOOD)
                woodProduced += unit.ProduceAmount / unit.Trip.length
            else if (unit.ProduceType == resource.Type.STONE)
                stoneProduced += unit.ProduceAmount / unit.Trip.length
        }
    }

    userstats.setPerRoundProduce(id, foodProduced, woodProduced, stoneProduced)
}

units.fromid = async (id) => {
    return database.getUnit(id)
}

units.getSpawns = async () => {
    return database.getUnitSpawns()
}

units.setSpawn = (pos) => {
    database.updateUnitSpawn(pos, 0)
}

units.removeSpawn = (pos) => {
    database.deleteUnitSpawn(pos)
}

units.getRange = async (start, amount) => {
    let idList = []

    for (let id = start; id < start + amount; id++)
        idList.push(id)

    let data = await database.getUnits(idList)
    let unitList = {}

    for (let i in data)
        if (data[i])
            unitList[i + start] = units.unitFromJSON(data[i])

    return unitList
}

units.unassignWork = async (unit) => {
    if (unit.Work) {
        await tiles.unassignWorker(unit.Work, unit)
        
        if (unit.Trip)
            userstats.removePerRoundProduce(unit.OwnerId, unit.ProduceType, unit.ProduceAmount / unit.Trip.length)
    }

    if (unit.Attack)
        units.revokeAttack(unit)

    unit.Work = undefined
    unit.Target = unit.Storage || unit.Home

    if (!units.isMilitary(unit))
        unit.Type = units.UnitType.VILLAGER

    database.updateUnit(unit.Id, unit)
}

units.assignWork = async (unit, pos) => {
    let tile = await tiles.fromPosString(pos)
    let type = tiles.getSafeType(tile)

    await units.unassignWork(unit)

	switch (type) {
		case tiles.TileType.FARM:
			unit.Type = units.UnitType.FARMER
			break
		case tiles.TileType.FORESTRY:
			unit.Type = units.UnitType.LUMBERJACK
			break
		case tiles.TileType.MINE:
			unit.Type = units.UnitType.MINER
			break
		case tiles.TileType.BARRACKS:
            if (unit.Type == units.UnitType.VILLAGER)
			    unit.Type = units.UnitType.APPRENTICE
            break
        case tiles.TileType.GRASS:
            break
        default:
            console.log("Attempted to assign unit to an invalid tile")
            console.log(unit)
            console.log(pos)
            return
    }
    
    unit.Work = pos
    unit.Target = pos
    
    if (units.isMilitary(unit)) {
        await units.computeMilitaryTrip(unit)
    } else {
        await units.computeTrip(unit)
        userstats.addPerRoundProduce(unit.OwnerId, unit.ProduceType, unit.ProduceAmount / unit.Trip.length)
    }

    database.updateUnit(unit.Id, unit)
}

units.assignAttack = (unit, pos) => {
    units.unassignWork(unit)
    unit.Target = pos
    unit.Attack = pos
    units.computeMilitaryTrip(unit)
}

units.revokeAttack = (unit) => {
    unit.Target = undefined
    unit.Work = undefined
    delete unit.Attack
    
    database.updateUnit(unit.Id, unit)
}

units.kill = (unit) => {
    //Remove them from their work
    units.unassignWork(unit)

    //Remove them from their home
    tiles.unassignWorker(unit.Home, unit)

    //Allow a new unit to be spawned in their place
    units.setSpawn(unit.Home)

    //Final update for clients
    unit.Health = 0
    database.updateUnit(unit.Id, unit)

    //Remove them entirely!
    delete Units[unit.Id]
    setTimeout(database.deleteUnit, 5000, unit.Id) //Allow clients to pick up 0 health and perform a local kill
}