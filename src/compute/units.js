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

units.UnitFields = [
    "Id", 
    "OwnerId", 
    "Position", 
    "Type", 
    "Health", 
    "Fatigue", 
    "Training", 
    "MaxTraining", 
    "State", 
    "Home",
    "Work",
    "Target",
    "Storage",
    "HeldResource",
    "HeldAmount",
    "MilitaryWorkType",
    "StepsSinceStore",
    "PerRoundProduce",
    "ResourceCollected",
    "TripLength",
    "AmountPerTrip",
    "Attack",
]

units.initialiseNewUnit = async (unitId, ownerId, pos) => {

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

    await database.updateUnit(unit, true)
    database.pushUnitToCollection(unit.OwnerId, unitId)

    return unit
}

units.addResource = async (unit, res, amount) => {
    unit.HeldAmount = parseFloat(unit.HeldAmount)
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

units.establishState = (unit) => {

    if (unit.Health <= 0)
        return UnitState.DEAD

    if (unit.Target && unit.Position != unit.Target)
        return UnitState.MOVING

    if (unit.Work && unit.Position == unit.Work)
        return UnitState.WORKING

    if (unit.Position == unit.Storage && unit.HeldResource)
        return UnitState.STORING

    if (unit.Fatigue > 0 && unit.Position == unit.Home)
        return UnitState.RESTING

    if (!unit.Work)
        return UnitState.IDLE
    
    return UnitState.LOST
}

units.establishMilitaryState = (unit) => {

    if (unit.Health <= 0)
        return UnitState.DEAD

    if (unit.Target && unit.Position != unit.Target)
        return UnitState.MOVING

    if (unit.Attack || unit.AttackUnit)
        return UnitState.COMBAT

    if (unit.WorkType == tiles.TileType.BARRACKS)
        return UnitState.TRAINING

    if (unit.WorkType == tiles.TileType.GRASS)
        return UnitState.GUARDING

    if (unit.Fatigue > 0 && unit.Position == unit.Home)
        return UnitState.RESTING
    
    if (!unit.Work)
        return UnitState.IDLE

    return UnitState.LOST
}

units.processUnit = async (unit, inCombat) => {
    if (!unit) return

    if (units.isMilitary(unit))
        return await units.processMilitaryUnit(unit, inCombat)

    if (inCombat) {
        unit.Target = unit.Home
    } else if (unit.State == units.UnitState.LOST) {
        unit.Target = unit.Work
    }

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
                let [storage, distance] = await tiles.findClosestStorageDist(unit.Work)

                if (distance > common.MAX_STORAGE_DIST) {
                    units.unassignWork(unit)
                } else {
                    unit.Target = storage
                    unit.Storage = storage
                }
            }

            break

        case UnitState.RESTING:
            userstats.use(unit.OwnerId, resource.Type.FOOD, common.FATIGUE_RECOVER_RATE * common.FOOD_PER_FATIGUE)  
            unit.Fatigue = parseInt(unit.Fatigue)

            if (unit.Fatigue <= common.FATIGUE_RECOVER_RATE){
                unit.Fatigue = 0

                if (unit.Work) {
                    let [storage, distance] = await tiles.findClosestStorageDist(unit.Work)
                    if (distance > common.MAX_STORAGE_DIST) {
                        units.unassignWork(unit)
                    } else {
                        unit.Target = unit.Work
                    }
                }

            } else {
                unit.Fatigue -= common.FATIGUE_RECOVER_RATE
            }

            break
        
        case UnitState.STORING:
            let perRoundProduce = unit.HeldAmount / unit.StepsSinceStore
            
            if (Number.isFinite(perRoundProduce)) {
                if (perRoundProduce != unit.PerRoundProduce || unit.HeldResource != unit.ResourceCollected) {

                    if (unit.ResourceCollected) {
                        let oldFood = (common.MAX_FATIGUE * common.FOOD_PER_FATIGUE) / unit.TripLength
                        userstats.removePerRoundProduce(unit.OwnerId, unit.ResourceCollected, unit.PerRoundProduce)
                        userstats.addPerRoundProduce(unit.OwnerId, resource.Type.FOOD, oldFood)
                    }

                    let newFood = (common.MAX_FATIGUE * common.FOOD_PER_FATIGUE) / unit.StepsSinceStore
                    userstats.removePerRoundProduce(unit.OwnerId, resource.Type.FOOD, newFood)
                    userstats.addPerRoundProduce(unit.OwnerId, unit.HeldResource, perRoundProduce)
                    unit.TripLength = unit.StepsSinceStore
                    unit.ResourceCollected = unit.HeldResource
                    unit.AmountPerTrip = unit.HeldAmount
                    unit.PerRoundProduce = perRoundProduce
                }

                userstats.add(unit.OwnerId, unit.HeldResource, unit.HeldAmount)
            }

            delete unit.HeldResource
            unit.HeldAmount = 0
            unit.StepsSinceStore = 0
            unit.Target = unit.Home

            break
    }

}

units.calculateAttackTarget = async (unit) => {

    //If attacking a tile
    if (unit.Attack) {
        let path = await tiles.findMilitaryPath(unit.Position, unit.Attack);
        
        //If can attack then go there, otherwise find closest unit to attack
        if (path && path.length >= 2) {
            let tile = await tiles.fromPosString(unit.Attack)
            unit.attackedId = tile.OwnerId
            return unit.Target = path[path.length - 2]
        } else if (path && path.length == 1) {
            let tile = await tiles.fromPosString(unit.Attack)
            unit.attackedId = tile.OwnerId
            return unit.Target = unit.Position
        } else {
            let closest = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id)
            unit.AttackUnit = closest
            unit.Attack = ""
            unit.attackedId = ""
        }
    }

    //If attacking a unit
    if (unit.AttackUnit) {
        let [ownerId, unitId] = unit.AttackUnit.split(":")
        let hostile = await database.getUnit(ownerId, unitId)

        //If unit to attack doesn't exist then give up
        if (!hostile || hostile.Health <= 0) {
            unit.AttackUnit = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id)
            unit.Attack = ""
            unit.attackedId = ""
            return
        }

        let path = await tiles.findMilitaryPath(unit.Position, hostile.Position);

        //If can attack then go there, otherwise find closest unit to attack
        if (path && path.length >= 2) {
            unit.attackedId = hostile.OwnerId
            return unit.Target = path[path.length - 2]
        } else if (path && path.length == 1) {
            unit.attackedId = hostile.OwnerId
            return unit.Target = unit.Position
        } else {
            unit.AttackUnit = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id)
            unit.Attack = ""
            unit.attackedId = ""
        }
    }

    unit.Target = unit.Work
}

units.processMilitaryUnit = async (unit, inCombat) => {

    if (units.establishMilitaryState(unit) == UnitState.DEAD) {
        units.revokeAttack(unit)
        unit.State = UnitState.DEAD
        units.handleDeath(unit)
        return
    }

    if (inCombat) {
        unit.AttackUnit = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id)
        //await units.calculateAttackTarget(unit)
    }

    if (unit.Attack || unit.AttackUnit)
        await units.calculateAttackTarget(unit)

    if (!unit.Target && unit.Work)
        unit.Target = unit.Work

    if (unit.Position == unit.Target) {
        let collision = await tiles.fastUnitCollisionCheck(unit.Position)

        //If this isn't the only unit on this tile, move to a free one
        for (let unitKey of collision) {
            let otherId = unitKey.split(":")[1]

            if (otherId < unit.Id) {
                let attackLocation 

                if (unit.Attack) {
                    attackLocation = unit.Attack
                } else if (unit.AttackUnit) {
                    let [ownerId, unitId] = unit.AttackUnit.split(":")
                    let hostile = await database.getUnit(ownerId, unitId)
                    
                    if (hostile)
                        attackLocation = hostile.Position
                }

                if (attackLocation)
                    unit.Target = await tiles.closestTileToResolveCollision(unit.Position, attackLocation)
            }
        }
    }

    let state = units.establishMilitaryState(unit)
    unit.State = state

    if (unit.State == UnitState.GUARDING && unit.Position != unit.Work) {
        unit.Target = unit.Work
        unit.State = UnitState.MOVING
    }

    switch (state) {
        case UnitState.MOVING:
            database.resetFullSimQuota(unit.OwnerId)
            let path = await tiles.findMilitaryPath(unit.Position, unit.Target);

            if (!path || path.length == 0)
                unit.State = UnitState.LOST
            else if (!await tiles.fastUnitCollisionCheck(path[0]))
                unit.Position = path[0]

            break

        case UnitState.TRAINING:
            unit.Training++

            if (unit.Type == UnitType.APPRENTICE && unit.Training >= common.TRAINING_FOR_SOLDIER){
                unit.Type = UnitType.SOLDIER
                unit.Training = 0
                unit.MaxTraining = 10000
            }

            break

        case UnitState.COMBAT:
            database.resetFullSimQuota(unit.OwnerId)
            let health
            if (unit.Attack) {
                let distance = tiles.costHeuristic(unit.Position, unit.Attack)

                if (distance == 1)
                    health = await database.incrementTileProp(unit.Attack, "Health", -10)
                else
                    units.calculateAttackTarget(unit)
            } 
            if (unit.AttackUnit) {
                let [otherOwnerId, otherUnitId] = unit.AttackUnit.split(":")
                let otherUnit = await database.getUnit(otherOwnerId, otherUnitId)

                if (otherUnit && tiles.costHeuristic(unit.Position, otherUnit.Position) == 1)
                    health = await database.damageUnit(otherUnit, 10) 
                else
                    units.calculateAttackTarget(unit)
            }

            if (health != undefined) {
                health = parseInt(health)

                if (health <= 0) {
                    //unit.AttackUnit = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id, unit.AttackUnit)
                } else {
                    userstats.setInCombat(unit.OwnerId)
                    if (unit.attackedId)
                        userstats.setInCombat(unit.attackedId)
                }            
            } else {
                unit.AttackUnit = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id)
            }

            break
    }
}

units.processSpawns = async (id) => {
    let UnitSpawns = await database.getUnitSpawns(id)

    for (let pos in UnitSpawns) {
		let tile = await tiles.fromPosString(pos)

        if (await userstats.canAfford(tile.OwnerId, resource.Type.FOOD, common.SPAWN_REQUIRED_FOOD)) {  
            UnitSpawns[pos] = parseInt(UnitSpawns[pos])
			if (UnitSpawns[pos] > common.SPAWN_ATTEMPTS_REQUIRED) {
                units.spawn(pos)
            } else {
                database.updateUnitSpawn(id, pos, UnitSpawns[pos] + 1)
            }
        }
    }
}

units.spawn = async (pos) => {
    let tile = await tiles.fromPosString(pos)
    let id = (await database.incrementUnitCount()).toString()
    let unit = await units.initialiseNewUnit(id, tile.OwnerId, pos)

    userstats.use(unit.OwnerId, resource.Type.FOOD, 100)
    tile.UnitList.push(id)
    database.updateTile(pos, tile)

    if (tile.UnitList.length >= common.HOUSE_UNIT_NUMBER) {
        database.deleteUnitSpawn(tile.OwnerId, pos)
    } else {
        database.updateUnitSpawn(tile.OwnerId, pos, 0)
    }

    return unit
}

units.getUnitCount = async () => {
    return database.getUnitCount()
}

units.fromid = async (ownerId, id) => {
    return database.getUnit(ownerId, id)
}

units.getSpawns = async () => {
    return database.getUnitSpawns()
}

units.setSpawn = (id, pos) => {
    database.updateUnitSpawn(id, pos, 0)
}

units.removeSpawn = async (id, pos) => {
    await database.deleteUnitSpawn(id, pos)
}

units.unassignWork = async (unit) => {
    if (unit.Work)
        await tiles.unassignWorker(unit.Work, unit)

    if (unit.Attack)
        units.revokeAttack(unit)

    unit.Work = ""
    unit.Attack = ""
    unit.AttackUnit = ""
    unit.Target = await tiles.findClosestStorage(unit.Position)

    if (!units.isMilitary(unit))
        unit.Type = units.UnitType.VILLAGER

    return await database.updateUnit(unit)
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
                unit.WorkType = type
            break
        case tiles.TileType.GRASS:
            unit.WorkType = type
            break
        default:
            console.log("Attempted to assign unit to an invalid tile")
            console.log(unit)
            console.log(pos)
            return
    }
    
    unit.Work = pos
    unit.Target = pos

    database.updateUnit(unit)
}

units.slowUnitDistance = async (unit, combinedKey) => {
    let [ownerId, unitId] = combinedKey.split(":")
    let otherUnit = await database.getUnit(ownerId, unitId)
    
    if (otherUnit)
        return tiles.costHeuristic(unit.Position, otherUnit.Position)
}

units.assignAttack = async (unit, pos) => {
    //await units.unassignWork(unit)

    unit.Attack = pos
    unit.Target = pos

    await database.updateUnit(unit)
}

units.revokeAttack = (unit) => {
    unit.Target = ""
    unit.Attack = ""
    unit.AttackUnit = ""
}

units.handleDeath = async (unit) => {
    unit.Health = 0
    unit.State = units.UnitState.DEAD
    let ops = [
        database.removeUnitFromCollection(unit.OwnerId, unit.Id),
        database.setDeadUnitExpiration(unit),
        database.updateUnitSpawn(unit.OwnerId, unit.Home, 0),
        database.removeUnitFromHome(unit),
        units.unassignWork(unit),
        database.updateUnit(unit, true),
    ]

    await Promise.all(ops)
}

units.processFastRoundSim = async (id, roundDelta) => {
    let req = {}
    req[id] = await database.getUnitCollection(id)
    let unitList = await database.getUnits(req)

    for (let unit of unitList) {
        if (unit.State == UnitState.TRAINING) {
            unit.Training = parseInt(unit.Training)
            unit.Training += roundDelta

            if (unit.Type == UnitType.APPRENTICE && unit.Training >= common.TRAINING_FOR_SOLDIER){
                unit.Type = UnitType.SOLDIER
                unit.Training = unit.Training - common.TRAINING_FOR_SOLDIER
                unit.MaxTraining = 10000
            }
        }
    }

    await database.updateUnits(unitList)
}