
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
	//Tile is currently empty
	if (!tiles.isEmpty(pos))
		return false

	//Tile is not within the land claim range of another civ
	let area = tiles.getCircularCollection(pos, common.LAND_CLAIM_RADIUS)
	for (let tile of area) 
		if (tile.OwnerId && tile.OwnerId != id)
			return false

	//User can afford to build
	let cost = tiles.TileConstructionCosts[type]

	if (!userstats.canAfford(id, resource.Type.WOOD, cost[resource.Type.WOOD]))
		return false

	if (!userstats.canAfford(id, resource.Type.STONE, cost[resource.Type.STONE]))	
		return false

	//Special case for keep
	if (type == tiles.TileType.KEEP && !userstats.hasKeep(id))
		return true

	//Special case for gates
	if (type == tiles.TileType.GATE && tiles.isWallGap(pos))
		return true

	//Tile is attached to a path
	let neighbours = tiles.getNeighbours(pos)

	for (let neighbour of neighbours)
		if (tiles.isWalkable(neighbour))
			return true
}

function verifyTilePlacement(id, pos, type) {

	if (!canBuild(id, pos, type))
		return
	
	let cost = tiles.TileConstructionCosts[type]
	userstats.use(id, resource.Type.WOOD, cost[resource.Type.WOOD])
	userstats.use(id, resource.Type.STONE, cost[resource.Type.STONE])
	userstats.addTileMaintenance(id, tiles.TileMaintenanceCosts[type])
	
	new tiles.Tile(type, id, pos)
	units.recomputeCiv(id)
}

function verifyWorkAssignment(id, unitid, pos) {
	let unit = units.fromid(unitid)

	if (!unit || id != unit.OwnerId)
		return

	if (!tiles.canAssignWorker(pos, unit))
		return 
	
	tiles.assignWorker(pos, unit)
	units.assignWork(unit, pos)
}

function verifyTileDeletion(id, pos) {
	let tile = tiles.fromPosString(pos)

	if (tile && tile.OwnerId == id && tile.UnitList.length == 0) {
		userstats.removeTileMaintenance(id, tiles.TileMaintenanceCosts[tile.Type])
		tiles.deleteTile(pos)
	}
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
                //verifyAttackAssignment(redis, action.id, action.unit, action.position)
                break
            case common.Actions.DELETE_TILE:
                verifyTileDeletion(action.id, action.position)
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
	await sendComputeRequest(units.getRange(0, 100))

	let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
	let outInfo = `Total: ${timeTaken}ms`;
	console.log(outInfo)

	database.updateStatus(Math.round(performance.now()), "ok: " + outInfo)
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
			res.on("data", (rawdata) => {
				let data = JSON.parse(rawdata)
				
				for (statChange of data.statChanges)
					userstats.add(statChange.Id, statChange.Type, statChange.Amount)

				units.updateState(data.units)

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
process.on("uncaughtException", (error) => {console.log("!!Encountered an error: " + error)})