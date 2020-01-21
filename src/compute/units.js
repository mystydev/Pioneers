let units = module.exports = {}
let database = require("./database")
let tiles = require("./tiles")
let userstats = require("./userstats")
let resource = require("./resource")
let common = require("./common")

const pvpMovementDepth = 20

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

units.establishState = async (unit) => {

    const hasTarget = unit.Target && unit.Target != ""

    if (unit.Health <= 0)
        return UnitState.DEAD

    if (hasTarget && unit.Position != unit.Target)
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

units.establishMilitaryState = async (unit) => {

    const hasTarget = unit.Target && unit.Target != ""
    const onGuardpost = await tiles.fastCheckGuardpost(unit.OwnerId, unit.Position)
    const inCombat = await userstats.isInCombat(unit.OwnerId)

    if (unit.Health <= 0)
        return UnitState.DEAD

    if (hasTarget && unit.Position != unit.Target)
        return UnitState.MOVING

    if (inCombat && (unit.Attack || unit.AttackUnit))
        return UnitState.COMBAT

    if (unit.WorkType == tiles.TileType.BARRACKS)
        return UnitState.TRAINING

    if (onGuardpost)
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
        let path = await tiles.findMilitaryPath(unit.Position, unit.Attack, unit.OwnerId);
        
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

        let path = await tiles.findMilitaryPath(unit.Position, hostile.Position, unit.OwnerId);

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

    let state = await units.establishMilitaryState(unit)

    if (state == UnitState.DEAD) {
        units.revokeAttack(unit)
        unit.State = UnitState.DEAD
        units.handleDeath(unit)
        return
    }

    if (!unit.Position)
        unit.Position = unit.Home

    if (inCombat) {
        //unit.AttackUnit = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id)
        //await units.calculateAttackTarget(unit)
    } else {
        unit.Attack = ""
        unit.AttackUnit = ""
        unit.InWar = ""
    }

    //if (unit.Attack || unit.AttackUnit)
        //await units.calculateAttackTarget(unit)

    if (!unit.Target && unit.Work)
        unit.Target = unit.Work

    if (unit.Position == unit.Target) {
        let collision = await tiles.fastUnitCollisionCheck(unit.Position) || []

        //If this isn't the only unit on this tile, move to a free one
        if (collision.length > 1 && unit.Position != unit.Home) {
            for (let unitKey of collision) {
                let otherId = unitKey.split(":")[1]

                if (otherId < unit.Id) {
                    /*let attackLocation 

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
                    else
                        unit.Target = await tiles.closestTileToResolveCollision(unit.Position, unit.Target)*/
                    unit.Target = await tiles.closestTileToResolveCollision(unit.Position, unit.Target)
                }
            }
        }
    }

    state = await units.establishMilitaryState(unit)
    unit.State = state

    /*if (unit.State == UnitState.GUARDING && unit.Position != unit.Work) {
        unit.Target = unit.Work
        unit.State = UnitState.MOVING
    }*/

    switch (state) {
        case UnitState.MOVING:
            database.resetFullSimQuota(unit.OwnerId)
            let path = await tiles.findMilitaryPath(unit.Position, unit.Target, unit.OwnerId);

            if (!path || path.length == 0)
                unit.State = UnitState.LOST
            else {
                //const index = Math.min(2, path.length) - 1
                const newPosition = common.roundDecimalPositionString(path[0])
                tiles.updateFastCollisionCache(unit.Position, newPosition, unit)
                unit.Position = newPosition
            }
                

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
                    //userstats.setInCombat(unit.OwnerId)
                    //if (unit.attackedId)
                        //userstats.setInCombat(unit.attackedId)
                }            
            } else {
                //unit.AttackUnit = await tiles.fastClosestHostileUnitToPosition(unit.OwnerId, unit.Position, unit.Id)
            }

            break

        /*case UnitState.GUARDING:
            const onGuardPost = await tiles.fastCheckGuardpost(unit.OwnerId, unit.Position)

            if (!onGuardPost) {
                unit.Work = ""
                unit.Attack = ""
                unit.AttackUnit = ""
                unit.WorkType = ""
                unit.State = UnitState.IDLE
            }*/

        case UnitState.IDLE:
            if (!unit.InWar)
                unit.Target = unit.Home
            break

        case UnitState.LOST:
            unit.Target = unit.Home
            break
    }

    //Correct any positions which were somehow incorrectly assigned (ie 1.335 instead of 1.333)
    unit.Position = common.roundDecimalPositionString(unit.Position)
    unit.Target = common.roundDecimalPositionString(unit.Target)
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
    unit.WorkType = ""
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

units.processEmptyGuardposts = async (id, unitList) => {
    const guardposts = await database.getGuardposts(id)
    let idleSoldiers = []
    let emptyGuardposts = []

    for (let position of guardposts)
        if (!await tiles.fastUnitCollisionCheck(position))
            emptyGuardposts.push(position)

    if (emptyGuardposts.length == 0)
        return

    for (let unit of unitList) {

        if (!units.isMilitary(unit))
            continue

            
        if (emptyGuardposts.includes(unit.Target)) {
            emptyGuardposts.splice(emptyGuardposts.indexOf(unit.Target), 1)
            continue
        }

        let state = await units.establishMilitaryState(unit)

        const noWork = !unit.Work || unit.Work == ""
        const noAttack = !unit.InWar
        let isIdle = state == UnitState.IDLE
        isIdle = isIdle || state == UnitState.LOST
        isIdle = isIdle || (state == UnitState.MOVING && noWork && noAttack)

        if (isIdle)
            idleSoldiers.push(unit)        
    }

    if (idleSoldiers.length == 0)
        return

    let distances = {}
    let unitMap = {}

    for (let unit of idleSoldiers) {
        distances[unit.Id] = {}
        unitMap[unit.Id] = unit


        for (let position of emptyGuardposts) {
            distances[unit.Id][position] = tiles.costHeuristic(unit.Position, position)
            //const path = await tiles.findMilitaryPath(unit.Position, position, unit.OwnerId) //Is this super expensive?
            //const dist = path ? path.length : Infinity
            //distances[unit.Id][position] = dist
        }
    }

    let toAssign = Math.min(idleSoldiers.length, emptyGuardposts.length)
    let maxiterations = 2000
    let iterations = 0

    while (toAssign > 0 && iterations < maxiterations) {
        iterations++

        //Check for single possible position, if so then assign
        let positionOccurances = {}
        let invalidatedPositions = []

        for (let unitId in distances) {

            let positions = Object.keys(distances[unitId])

            if (positions.length == 0) {
                delete distances[unitId]
                continue
            } else if (positions.length == 1) {
                unitMap[unitId].Target = positions[0]
                toAssign--
                invalidatedPositions.push(positions[0])
                break
            }

            for (let position in distances[unitId]) {
                if (positionOccurances[position])
                    positionOccurances[position] += 1
                else
                    positionOccurances[position] = 1
            }
        }

        if (invalidatedPositions.length == 0) {
            for (let position in positionOccurances) {
                const occurances = positionOccurances[position]

                if (occurances == 1) {
                    for (let unitId in distances) {
                        if (distances[unitId][position]) {
                            unitMap[unitId].Target = position
                            toAssign--
                            delete distances[unitId]
                        }
                    }
                }
            }
        } else {
            for (let position of invalidatedPositions)
                for (let unitId in distances)
                    if (distances[unitId][position]) 
                        delete distances[unitId][position]

        }

        //Remove longest distance
        let longest = 0
        let furthestUnit
        let furthestPosition

        for (let unitId in distances) {
            for (let position in distances[unitId]) {
                let distance = distances[unitId][position]

                if (distance > longest) {
                    longest = distance
                    furthestUnit = unitMap[unitId]
                    furthestPosition = position
                }
            }
        }

        if (longest != 0) {
            delete distances[furthestUnit.Id][furthestPosition]
        }

    }


    await database.updateUnits(idleSoldiers)
}

units.evaluateCombatMovement = async (unitList, friendlyId, hostileId) => {

    let friendlyPositionOverrides = {}

    for (let i = 0; i < 3; i++) {
        //Collect all military unit locations
        //All friendly units, all hostile units in same and surrounding partitions
        let friendlyUnitLocations = new Set()
        let hostileUnitLocations = new Set()
        let partitions = new Set()
        let unitPosToInstMap = {}
        let hostilePosToIdMap = {}

        //Collect friendly units and relevant partitions
        for (let unit of unitList) {
            if (units.isMilitary(unit)) {
                let position

                if (friendlyPositionOverrides[unit.Id]) {
                    position = friendlyPositionOverrides[unit.Id][0]
                    //console.log(position)
                } else {
                    position = unit.Position
                }
            
                friendlyUnitLocations.add(position)
                unitPosToInstMap[position] = unit
                partitions.add(unit.PartitionId)
                const neighbours = common.getNeighbouringPartitionIds(unit.PartitionId)
                neighbours.forEach(id => partitions.add(id))
            }
        }

        //Collect hostile units
        for (let id of partitions) {
            const positions = await database.getMilitaryUnitPositionsInPartition(id)

            for (let position in positions) {
                for (let id of positions[position]) {
                    if (id.split(":")[0] == hostileId) {
                        hostileUnitLocations.add(position)
                        hostilePosToIdMap[position] = id
                    }
                }
            }
        }

        //Generate node graph
        let nodes = {}
        let edgeNodes = []

        hostileUnitLocations.forEach(position => {
            nodes[position] = {
                weight: 0,
                moving: false,
                inbound: false,
                destination: undefined,
            }

            edgeNodes.push(position)
        })

        let inCombatFriendlies = new Set()

        for (let position of edgeNodes) {
            for (let neighbour of tiles.getHighResNeighbourPositions(position)) {
                if (friendlyUnitLocations.has(neighbour)) {
                    inCombatFriendlies.add(neighbour)
                    unitPosToInstMap[neighbour].AttackUnit = hostilePosToIdMap[position]
                }
            }
        }

        //Flood fill weightings
        for (let depth = 1; depth < pvpMovementDepth; depth++) {
            let newEdges = new Set()

            for (let position of edgeNodes) {
                if (nodes[position] && nodes[position].weight == depth - 1) {
                    for (let neighbour of tiles.getHighResNeighbourPositions(position)) {
                        newEdges.add(neighbour)
                    }
                }
            }
                    
            for (let position of newEdges) {
                //Ignore in combat units as they cannot move
                if (inCombatFriendlies.has(position)) {
                    continue
                } else if (!nodes[position]) {
                    nodes[position] = {
                        weight: depth,
                        moving: false,
                        inbound: false,
                        destination: undefined,
                    }
                }
            }

            edgeNodes = newEdges
        }

        //Generate movement chains
        //For each depth level
            //Propose movement
            //Evaluate and confirm all non-conflicting movements
            //Reevaluate movements until none left or all remaining are conflicting

        for (let depth = 2; depth < pvpMovementDepth; depth++) {
            let movements = {}
            let possibilities = {}

            //Propose movements
            for (let position in nodes) {
                let node = nodes[position]

                if (friendlyUnitLocations.has(position) && !inCombatFriendlies.has(position) && node.weight == depth) {
                    possibilities[position] = []

                    for (let neighbour of tiles.getHighResNeighbourPositions(position)) {
                        const isMoving = nodes[neighbour] && nodes[neighbour].moving
                        const canWalk = isMoving || !friendlyUnitLocations.has(neighbour)
                        const lessDepth = nodes[neighbour] ? nodes[neighbour].weight < depth : false

                        if (canWalk && lessDepth) {
                            movements[neighbour] = movements[neighbour] || []
                            movements[neighbour].push(position)
                            possibilities[position].push(neighbour)
                        }
                    }
                }
            }

            //Evaluate conflicts
            let wasConflict = true
            let updated = true
            let iterations = 0

            while (wasConflict && updated && (iterations++) < 300) {
                wasConflict = false
                updated = false

                for (let destination in movements) {
                    let inbound = movements[destination]
                    let requests = 0
                    let from
                    let lowestPossibilities = 100

                    for (let p of inbound) {
                        if (!nodes[p].moving) {
                            requests++

                            if (possibilities[p].length < lowestPossibilities) {
                                from = p
                                lowestPossibilities = possibilities[p].length
                            }
                        }
                    }

                    if (from && !nodes[destination].inbound) {
                        updated = true
                        nodes[from].moving = true
                        nodes[from].destination = destination
                        nodes[destination].inbound = true
                    } else if (requests > 1) {
                        wasConflict = true
                    }
                }
            }

            
            if (iterations >= 300) {
                console.log("Hit iteration cap!")
            }
        }

        for (let u in nodes) {
            let destination = nodes[u].destination
            if (destination) {
                const unit = unitPosToInstMap[u]
                
                if (friendlyPositionOverrides[unit.Id]) {
                    let positionOverride = friendlyPositionOverrides[unit.Id][0]
                    tiles.updateFastCollisionCache(unit.Position, positionOverride, unit)
                    unit.Position = positionOverride
                }
            
                friendlyPositionOverrides[unit.Id] = [destination, unit]
            }
        }
    }

    for (let unitId in friendlyPositionOverrides) {
        const [destination, unit] = friendlyPositionOverrides[unitId]
        unit.Target = destination
        unit.InWar = true
    }
}