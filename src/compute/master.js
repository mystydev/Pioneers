
let http = require("http")
let performance = require('perf_hooks').performance
let database = require("./database")

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
	interval = setInterval(processRound, 2000)
}

async function processRound() {
	database.setRoundStart()
	let start = performance.now()
	let playerList = await database.getPlayerList()
	let processing = []

	for (let userId of playerList)
		processing.push(sendComputeRequest(userId))

	await Promise.all(processing)

	let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
	let outInfo = `Total: ${timeTaken}ms`;
	console.log(outInfo)

	database.updateStatus(Date.now(), "ok: " + outInfo)
}

async function sendComputeRequest(userId) {
	let req = http.request(options)

	req.on("error", (e) => {
		console.log("Failed to send compute request: " + e)
	})

	req.write(userId)
	req.end()

	return new Promise ((resolve) => {
		req.on("response", () => {
			resolve()
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