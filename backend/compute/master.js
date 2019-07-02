
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

function verifyTilePlacement(id, pos, type) {
	new tiles.Tile(type, id, pos)
}

function verifyWorkAssignment(id, unitid, pos) {
	let tile = tiles.fromPosString(pos)
	let unit = units.fromid(unitid)

	switch (tile.Type) {
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
			unit.Type = units.UnitType.APPRENTICE
			break
	}

	unit.Work = pos
	unit.Target = pos

	database.updateUnit(unitid, unit)

	console.log("Work assigned")
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
                //verifyTileDelete(redis, action.id, action.position)
                break
            default:
                console.log("Unknown action!", action)
        }
    }
}

async function processRound() {
	let start = performance.now()
	await units.load()
	let unitTime = performance.now()
	await processActionQueue()
	let actionTime = performance.now()
	units.processSpawns()
	let spawnTime = performance.now()
	await sendComputeRequest(units.getRange(0, 10))
	let computeTime = performance.now()

	let unitT = (unitTime - start).toFixed(1).toString().padStart(6, " ");
	let actionT = (actionTime - unitTime).toFixed(1).toString().padStart(6, " ");
	let spawnT = (spawnTime - actionTime).toFixed(1).toString().padStart(6, " ");
	let computeT = (computeTime - spawnTime).toFixed(1).toString().padStart(6, " ");
	let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");

	let outInfo = `Total: ${timeTaken}ms (unitload ${unitT} actions ${actionT} spawns ${spawnT} compute ${computeT})`;
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