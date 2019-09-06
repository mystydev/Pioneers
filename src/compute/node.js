
let database = require("./database")
let tiles = require("./tiles")
let units = require("./units")
let common = require("./common")
let userstats = require("./userstats")
let performance = require('perf_hooks').performance
let express = require("express")
let bodyParser = require("body-parser")
let PORT = 6420;

let httpserver = express()
httpserver.use(bodyParser.json({ limit: '5mb', strict: false}))

function shutdown(code) {
    console.log("Compute node shutting down: " + code)
    
	database.disconnect()
	process.exit(0) //Bit forceful, but we don't care, everything should be in a safe state anyway
}

function handleNewPlayer(id) {
	console.log("New player joined with id:", id)
	userstats.newPlayer(id)
}

async function canBuild(id, pos, type) {
	//Start fetching data from db early to minimise waiting
	let tile = tiles.fromPosString(pos)
	let area = tiles.getCircularCollection(pos, common.LAND_CLAIM_RADIUS)
	let neighbours = tiles.getNeighbours(pos)

	//Tile is currently empty with no units assigned
    tile = await tile
	if (!tiles.isEmpty(tile) || !tiles.isVacant(tile))
		return false

	//Tile is not within the land claim range of another civ
    area = await area
	for (let tile of area) 
		if (tile.OwnerId && tile.OwnerId != id)
			return false

	//User can afford to build
	let cost = tiles.TileConstructionCosts[type]
	if (!await userstats.canAffordCost(id, cost))
		return false

	//Special case for keep
	if (type == tiles.TileType.KEEP && !await userstats.hasKeep(id))
		return true

	//Special case for gates
	if (type == tiles.TileType.GATE && tiles.isWallGap(pos))
		return true

	//Tile is attached to a path
	neighbours = await neighbours
	for (let neighbour of neighbours)
		if (tiles.isWalkable(neighbour))
			return true
}

async function verifyTilePlacement(id, pos, type) {

	//Can the player build a tile of this type here
	if (!(await canBuild(id, pos, type)))
		return

	//Is the user currently in combat
	if (await userstats.isInCombat(id))
		return

	//Update users stats
	let cost = tiles.TileConstructionCosts[type]
	userstats.useCost(id, cost)
	userstats.addTileMaintenance(id, tiles.TileMaintenanceCosts[type])
    
	//Create tile and recompute cached values (like unit trips)
	new tiles.AuthoritativeTile(type, id, pos)
	//units.recomputeCiv(id)
}

async function verifyWorkAssignment(id, unitid, pos) {
    let unit = await units.fromid(unitid)
	
	console.log(unit)
	//Does the unit exist and is the unit owned by the player making the request
	if (!unit || id != unit.OwnerId)
		return

	//If there is no position then deassign the unit's work
	if (!pos)
		 return units.unassignWork(unit)

	//Is it a military unit and if not can it be assigned work
	if (!units.isMilitary(unit) && !await tiles.canAssignWorker(pos, unit))
		return 
	
	//If it is a military unit can it be assigned military work
	if (units.isMilitary(unit) && !await tiles.canAssignMilitaryWorker(pos, unit))
		return 

	//Assign the worker
	await tiles.assignWorker(pos, unit)
	await units.assignWork(unit, pos)
}

async function verifyAttackAssignment(id, unitid, pos) {
	let unit = await units.fromid(unitid)

	//Check if the unit exists, is owned by the same owner and is a military unit
	if (!unit || id != unit.OwnerId || !units.isMilitary(unit))
		return

	let tile = await tiles.fromPosString(pos)

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

async function verifyTileDeletion(id, pos) {
	let tile = await tiles.fromPosString(pos)

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
	if (await tiles.isFragmentationDependant(pos, userstats.getKeep(id)))
		return false

	//Remove maintenance cost from users stats, delete the tile and update cached unit values
	userstats.removeTileMaintenance(id, tiles.TileMaintenanceCosts[tile.Type])
	tiles.deleteTile(tile)
	units.recomputeCiv(id)
}

async function verifyTileRepair(id, pos) {
	let tile = await tiles.fromPosString(pos)

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

async function processActionQueue(id) {
    let actions = await database.getActionQueue(id)
    
	for (let index in actions) {
		let action = JSON.parse(actions[index])
		console.log("Processing:", action)

        switch(action.action){

            case common.Actions.NEW_PLAYER:
                handleNewPlayer(action.id)
                break
            case common.Actions.PLACE_TILE:
                await verifyTilePlacement(action.id, action.position, action.type)
                break
            case common.Actions.SET_WORK:
                await verifyWorkAssignment(action.id, action.unit, action.position)
                break
            case common.Actions.ATTACK:
                await verifyAttackAssignment(action.id, action.unit, action.position)
                break
            case common.Actions.DELETE_TILE:
                await verifyTileDeletion(action.id, action.position)
				break
			case common.Actions.REPAIR_TILE:
                await verifyTileRepair(action.id, action.position)
				break
            default:
                console.log("Unknown action!", action)
        }
	}

}


async function computeRequest(id) {
    console.log("Handling compute request:", id)
    let start = performance.now()
    let processing = []

    await processActionQueue(id)
    await units.processSpawns(id)
    await userstats.processMaintenance(id)

	let unitids = await database.getUnitCollection(id)
	let unitList = await database.getUnits(unitids)

    for (let unit of unitList)
        processing.push(units.processUnit(unit))

	await Promise.all(processing)
	database.updateUnits(unitList)

    let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
    console.log("Compute request took: " + timeTaken + "ms")
    
    return {}
}

function init() {
    console.log("Compute node initialising")

    database.connect()

    httpserver.listen(PORT, () => {
        console.log("Listening on port " + PORT)
    })
    
    console.log("Ready")
}

httpserver.post("/", (req, res) => {
    computeRequest(req.body).then(response => {
        res.json(response)
    })
})

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