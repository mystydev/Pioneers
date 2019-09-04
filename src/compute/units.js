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

units.initialiseNewUnit = (unitId, ownerId, pos) => {

    let unit = {
        Id: unitId,
        OwnerId: ownerId,
        Position: pos,
        Type: UnitType.VILLAGER,
        Health: 200,
        Fatigue: 0,
        Training: 0,
        MaxTraining: common.TRAINING_FOR_SOLDIER,
        State: UnitState.IDLE,
        Home: pos,
    }

    database.setUnitProps(unitId, unit)
    database.pushUnitToCollection(unit.OwnerId, unitId)

    return unit
}

units.addResource = async (unit, res, amount) => {
    unit.HeldAmount = parseInt(unit.HeldAmount)
    if (unit.HeldResource != res) {
        unit.HeldResource = res
        unit.HeldAmount = amount
    } else {
        unit.HeldAmount += amount
    }
}

units.isMilitary = (unit) => {
    return unit.Type == UnitType.APPRENTICE || unit.Type == UnitType.SOLDIER
}

units.establishState = async (unit) => {

    if (unit.Health <= 0)
        return UnitState.DEAD

    if (unit.Target && unit.Position != unit.Target)
        return UnitState.MOVING

    if (unit.Position == unit.Work)
        return UnitState.WORKING

    if (unit.Position == unit.Storage && unit.HeldResource)
        return UnitState.STORING

    if (unit.Fatigue > 0 && unit.Position == unit.Home)
        return UnitState.RESTING

    if (!unit.Work)
        return UnitState.IDLE
    
    return UnitState.LOST
}

/*units.establishMilitaryState = (unit) => {
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
}*/

units.processUnit = async (id) => {
    let unit = await database.getUnit(id)
    if (!unit.Id) return

    if (await units.isMilitary(unit))
        return units.processMilitaryUnit(unit)

    let state = await units.establishState(unit)
    unit.State = state

    if (state != UnitState.IDLE)
        unit.StepsSinceStore = parseInt(unit.StepsSinceStore || 0) + 1

    switch (state) {
        case UnitState.MOVING:
            let path = await tiles.findPath(unit.Position, unit.Target);

            if (path)
                unit.Position = path[0]
            else
                unit.State = UnitState.LOST

            break

        case UnitState.WORKING:
            let [res, amount] = await tiles.getOutput(unit.Work)

            units.addResource(unit, res, amount)
            unit.Fatigue = parseInt(unit.Fatigue)
            unit.Fatigue += 1

            if (unit.Fatigue >= common.MAX_FATIGUE){
                unit.Target = await tiles.findClosestStorage(unit.Position)
                unit.Storage = unit.Target
            }

            break

        case UnitState.RESTING:
            userstats.use(unit.OwnerId, resource.Type.FOOD, common.FATIGUE_RECOVER_RATE * common.FOOD_PER_FATIGUE)  
            unit.Fatigue = parseInt(unit.Fatigue)

            if (unit.Fatigue <= common.FATIGUE_RECOVER_RATE){
                unit.Fatigue = 0
                unit.Target = unit.Work
            } else {
                unit.Fatigue -= common.FATIGUE_RECOVER_RATE
            }

            break
        
        case UnitState.STORING:
            let perRoundProduce = Math.floor(unit.HeldAmount / unit.StepsSinceStore)

            if (perRoundProduce != unit.PerRoundProduce || unit.HeldResource != unit.ResourceCollected) {

                if (unit.ResourceCollected) {
                    let oldFood = Math.floor((common.MAX_FATIGUE * common.FOOD_PER_FATIGUE) / unit.TripLength)
                    userstats.removePerRoundProduce(unit.OwnerId, unit.ResourceCollected, unit.PerRoundProduce)
                    userstats.addPerRoundProduce(unit.OwnerId, resource.Type.FOOD, oldFood)
                }

                let newFood = Math.floor((common.MAX_FATIGUE * common.FOOD_PER_FATIGUE) / unit.StepsSinceStore)
                userstats.removePerRoundProduce(unit.OwnerId, resource.Type.FOOD, newFood)
                userstats.addPerRoundProduce(unit.OwnerId, unit.HeldResource, perRoundProduce)
                unit.TripLength = unit.StepsSinceStore
                unit.ResourceCollected = unit.HeldResource
                unit.AmountPerTrip = unit.HeldAmount
                unit.PerRoundProduce = perRoundProduce
            }

            userstats.add(unit.OwnerId, unit.HeldResource, unit.HeldAmount)
            database.delUnitProp(id, "HeldResource")
            database.delUnitProp(id, "HeldAmount")
            delete unit.HeldResource
            delete unit.HeldAmount

            unit.StepsSinceStore = 0

            if (unit.Fatigue > 0)
                unit.Target = unit.Home

            break
    }

    database.setUnitProps(id, unit)
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
    console.log("Spawning")
    let tile = await tiles.fromPosString(pos)
    let id = (await database.incrementUnitCount()).toString()
    let unit = units.initialiseNewUnit(id, tile.OwnerId, pos)

    userstats.use(unit.OwnerId, resource.Type.FOOD, 100)
    tile.UnitList.push(id)
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

units.unassignWork = async (unit) => {
    if (unit.Work)
        await tiles.unassignWorker(unit.Work, unit)

    if (unit.Attack)
        units.revokeAttack(unit)

    delete unit.Work
    database.delUnitProp(unit.Id, "Work")
    unit.Target = await tiles.findClosestStorage(unit.Position)

    if (!units.isMilitary(unit))
        unit.Type = units.UnitType.VILLAGER

    database.setUnitProps(unit.Id, unit)
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
    
    if (!units.isMilitary(unit)) {
        //userstats.addPerRoundProduce(unit.OwnerId, unit.ProduceType, unit.ProduceAmount / unit.Trip.length)
    }

    database.setUnitProps(unit.Id, unit)
}

units.assignAttack = async (unit, pos) => {
    await units.unassignWork(unit)
    unit.Target = pos
    unit.Attack = pos
    database.setUnitProps(unit.Id, unit)
}

units.revokeAttack = (unit) => {
    delete unit.Target
    delete unit.Work
    delete unit.Attack
    database.delUnitProp(unit.Id, "Target")
    database.delUnitProp(unit.Id, "Work")
    database.delUnitProp(unit.Id, "Attack")
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
    database.setUnitProps(unit.Id, unit)

    //Remove them entirely!
    setTimeout(database.deleteUnit, 5000, unit.Id) //Allow clients to pick up 0 health and perform a local kill
}