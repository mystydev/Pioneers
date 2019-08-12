
let http = require("http")
let performance = require('perf_hooks').performance
let common = require("./common")
let database = require("./database")
let tiles = require("./tiles")
let units = require("./units")
let userstats = require("./userstats")
let resource = require("./resource")

const options = {
	hostname: "computenode.dev",
	port: 6420,
	path: "/",
	method: "POST",
	headers: {
		"Content-Type": "application/json"
	}
}

let interval

function shutdown(code) {
	console.log("Compute master node shutting down: " + code)

	clearInterval(interval)
	database.disconnect()
	process.exit(0) //Bit forceful, but we don't care, everything should be in a safe state anyway
}

async function init() {
	console.log("Compute master node starting")

	database.connect()
	await userstats.load()
	await units.load()
	await tiles.load()

	console.log("Initialisation finished")
	interval = setInterval(processRound, 2000)
}

function handleNewPlayer(id) {
	userstats.newPlayer(id)
	units.newPlayer(id)
}

function canBuild(id, pos, type) {

	//Tile is currently empty with no units assigned
	if (!tiles.isEmpty(pos) || !tiles.isVacant(pos))
		return false

	//Tile is not within the land claim range of another civ
	let area = tiles.getCircularCollection(pos, common.LAND_CLAIM_RADIUS)
	for (let tile of area) 
		if (tile.OwnerId && tile.OwnerId != id)
			return false

	//User can afford to build
	let cost = tiles.TileConstructionCosts[type]

	if (!userstats.canAffordCost(id, cost))
		return false

	//Special case for keep
	if (type == tiles.TileType.KEEP && !userstats.hasKeep(id))
		return true

	//Special case for gates
	if (type == tiles.TileType.GATE && tiles.isWallGap(pos))
		return true

	//Tile is attached to a path
	for (let neighbour of tiles.getNeighbours(pos))
		if (tiles.isWalkable(neighbour))
			return true
}

function verifyTilePlacement(id, pos, type) {

	//Can the player build a tile of this type here
	if (!canBuild(id, pos, type))
		return

	//Is the user currently in combat
	if (userstats.isInCombat(id))
		return

	//Update users stats
	let cost = tiles.TileConstructionCosts[type]
	userstats.useCost(id, cost)
	userstats.addTileMaintenance(id, tiles.TileMaintenanceCosts[type])
	
	//Create tile and recompute cached values (like unit trips)
	new tiles.Tile(type, id, pos)
	units.recomputeCiv(id)
}

function verifyWorkAssignment(id, unitid, pos) {
	let unit = units.fromid(unitid)

	//Does the unit exist and is the unit owned by the player making the request
	if (!unit || id != unit.OwnerId)
		return

	//If there is no position then deassign the unit's work
	if (!pos)
		 return units.unassignWork(unit)

	//Is it a military unit and if not can it be assigned work
	if (!units.isMilitary(unit) && !tiles.canAssignWorker(pos, unit))
		return 
	
	//If it is a military unit can it be assigned military work
	if (units.isMilitary(unit) && !tiles.canAssignMilitaryWorker(pos, unit))
		return 

	//Assign the worker
	tiles.assignWorker(pos, unit)
	units.assignWork(unit, pos)
}

function verifyAttackAssignment(id, unitid, pos) {
	let unit = units.fromid(unitid)

	//Check if the unit exists, is owned by the same owner and is a military unit
	if (!unit || id != unit.OwnerId || !units.isMilitary(unit))
		return

	let tile = tiles.fromPosString(pos)

	//Check if the tile to attack exists and is not owned by the unit owner
	if (!tile || tiles.isWalkable(tile) || tile.OwnerId == unit.OwnerId)
		return

	//Find path to tile
	let path = tiles.findMilitaryPath(units.getPosition(unit), pos)

	//Check if path is found
	if (!path)
		return

	units.assignAttack(unit, pos, path)
}

function verifyTileDeletion(id, pos) {
	let tile = tiles.fromPosString(pos)

	//Does the tile exist
	if (!tile)
		return false

	//Is the tile owned by the player making the request
	if (tile.OwnerId != id)
		return false

	//Does the tile have any units assigned to it
	if (!tiles.isVacant(pos))
		return false

	//Will deleting this tile cause a kingdom fragmentation
	if (tiles.isFragmentationDependant(pos, userstats.getKeep(id)))
		return false

	//Remove maintenance cost from users stats, delete the tile and update cached unit values
	userstats.removeTileMaintenance(id, tiles.TileMaintenanceCosts[tile.Type])
	tiles.deleteTile(pos)
	units.recomputeCiv(id)
}

function verifyTileRepair(id, pos) {
	let tile = tiles.fromPosString(pos)

	//Does the tile exist
	if (!tile)
		return false

	//Is the tile owned by the player making the request
	if (tile.OwnerId != id)
		return false

	//Can the player afford to repair the tile
	let repairCost = tiles.getRepairCost(pos)

	if (!userstats.canAffordCost(id, repairCost))
		return false

	//Repair the tile!
	userstats.useCost(id, repairCost)
	tile.Health = tile.MaxHealth
	database.updateTile(pos, tile)
	units.recomputeCiv(id)
}

async function processActionQueue() {
	let actions = await database.getActionQueue()

	for (index in actions) {
        let action = JSON.parse(actions[index])

        switch(action.action){

            case common.Actions.NEW_PLAYER:
                handleNewPlayer(action.id)
                break
            case common.Actions.PLACE_TILE:
                verifyTilePlacement(action.id, action.position, action.type)
                break
            case common.Actions.SET_WORK:
                verifyWorkAssignment(action.id, action.unit, action.position)
                break
            case common.Actions.ATTACK:
                verifyAttackAssignment(action.id, action.unit, action.position)
                break
            case common.Actions.DELETE_TILE:
                verifyTileDeletion(action.id, action.position)
				break
			case common.Actions.REPAIR_TILE:
				verifyTileRepair(action.id, action.position)
				break
            default:
                console.log("Unknown action!", action)
        }
    }
}

async function processRound() {
	let start = performance.now()
	await processActionQueue()
	units.processSpawns()
	userstats.processMaintenance()

	let unitCount = units.getUnitCount()
	//for (let i = 0; i < unitCount; i += 1000){
		await sendComputeRequest(units.getRange(0, 1000))
	//}	

	let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
	let outInfo = `Total: ${timeTaken}ms`;
	console.log(outInfo)

	database.updateStatus(Date.now(), "ok: " + outInfo)
}

async function sendComputeRequest(data) {
	let req = http.request(options)

	req.on("error", (e) => {
		console.log("Failed to send compute request: " + e)
	})

	req.write(JSON.stringify(data))
	req.end()

	return new Promise ((resolve, reject) => {
		req.on("response", (res) => {
			res.setEncoding("utf8")
			let rawdata = []

			res.on("data", (rawdataSlice) => {
				rawdata.push(rawdataSlice)
			})

			res.on("end", () => {
				try {
					let data = JSON.parse(rawdata.join(''))

					units.updateState(data.units)
					
					for (let statChange of data.stats)
						userstats.add(statChange.Id, statChange.Type, statChange.Amount)

					for (let damage of data.damage){
						let tile = tiles.fromPosString(damage.Pos)

						if (tile) {

							if (tile.UnitList.length == 0) {

								tile.Health -= damage.Health

								if (tile.Health <= 0) {
									console.log("Tile health 0!")
									tile.Health = 0
									units.revokeAttack(units.fromid(damage.UnitId))
									units.recomputeCiv(tile.OwnerId)
								}
							} else {
								let unit = units.fromid(tile.UnitList[0])
								let attackingUnit = units.fromid(damage.UnitId)
								
								unit.Health -= damage.Health
								attackingUnit.Health -= damage.Health //Replace with real damage
								unit.UnderAttack = attackingUnit

								if (unit.Health <= 0) {
									unit.Health = 0
									units.kill(unit)

									if (attackingUnit.Work != attackingUnit.Attack) {
										let work = attackingUnit.Work
										units.revokeAttack(attackingUnit)
										attackingUnit.Work = work
										attackingUnit.Target = work
										database.updateUnit(attackingUnit.Id, attackingUnit)
									}
								}
							}

							userstats.setInCombat(tile.OwnerId)
						}

						database.updateTile(damage.Pos, tile)
					}

					for (let userId of data.combat)
						userstats.setInCombat(userId)

					
				} catch (error) {
					console.error("Error parsing returned json from compute node")
					console.error("Returned json:")
					console.error(rawdata)
					console.error("Error message:")
					console.error(error)
				}

				resolve()
			})
		})
	})
}

init()

process.on("exit", shutdown)
process.on("SIGHUP", shutdown)
process.on("SIGINT", shutdown)
process.on("SIGTERM", shutdown)
process.on("uncaughtException", (error) => {
	console.error("!!Encountered an error: " + error.message)
	console.error(error.stack)
})
process.on('unhandledRejection', (error) => {
	console.error("!!Encountered a rejection: " + error.message)
	console.error(error.stack)
})