
let http = require("http")
let performance = require('perf_hooks').performance
let database = require("./database")
let Mutex = require('async-mutex').Mutex;

const options = {
	hostname: "computenode.dev",
	port: 6420,
	path: "/",
	method: "POST",
	timeout: 2000,
	headers: {
		"Content-Type": "application/json"
	}
}

let interval
let processingLock = new Mutex()

function shutdown(code) {
	console.log("Compute master node shutting down: " + code)

	clearInterval(interval)
	database.disconnect()
	process.exit(0) //Bit forceful, but we don't care, everything should be in a safe state anyway
}

function init() {
	console.log("Compute master node starting")
	database.connect()
	interval = setInterval(processRound, 2000)
}

function attemptRound() {
	if (!processingLock.isLocked())
		processingLock.acquire().then((release) => {
			processRound().then(() => release()).catch(() => release())
		})
		
	else
		console.log("Skipping round due to over time simulation")
}

async function processRound() {
	console.log("Processing")
	database.setRoundStart()
	let roundNumber = await database.getRoundCount()

	let start = performance.now()
	let playerList = await database.getLoadedKingdoms()
	let processing = []

	for (let userId of playerList)
		processing.push(sendComputeRequest({time: start, id: userId, round: roundNumber}))

	await Promise.all(processing)

	let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
	let outInfo = `Total: ${timeTaken}ms`;
	console.log(outInfo)

	database.updateStatus(Date.now(), "ok: " + outInfo)
	database.incrementRoundCount()
}

async function sendComputeRequest(data) {
	let req = http.request(options)

	req.on("error", (e) => {
		console.log("Failed to send compute request: " + e)
	})

	req.write(JSON.stringify(data))
	req.end()

	return new Promise ((resolve) => {
		req.on("response", () => {
			resolve()
		})

		req.on("timeout", () => {
			console.error("Compute request timed out")
			resolve()
		})
	})
}

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

init()