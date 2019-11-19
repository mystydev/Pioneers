
let http = require("http")
let performance = require('perf_hooks').performance
let database = require("./database")
let Mutex = require('async-mutex').Mutex;


const httpAgent = new http.Agent({
	keepAlive: true,
})

const options = {
	hostname: "computenode.dev",
	agent: httpAgent,
	port: 80,
	path: "/",
	method: "POST",
	timeout: 1900,
	headers: {
		"Content-Type": "application/json",
		"Connection": "keep-alive",
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

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function processRound() {

	database.setRoundStart()
	let roundNumber = await database.getRoundCount()
	console.log("Processing", roundNumber)

	let start = performance.now()
	let playerList = await database.getLoadedKingdoms()
	let processing = []

	for (let userId of playerList) {
		processing.push(sendComputeRequest({time: start, id: userId, round: roundNumber}))
	}

	await Promise.all(processing)

	let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
	let outInfo = `Total: ${timeTaken}ms`;
	console.log(outInfo)

	database.updateStatus(Date.now(), "ok: " + outInfo)
	database.incrementRoundCount()
}

async function sendComputeRequest(data) {
	return new Promise ((resolve) => {
	
		console.log("Sending: ", data)

		let req = http.request(options, (res) => {
			res.on("end", () => {
				resolve()
			})		
			
			res.on("aborted", () => {
				console.log("Compute request aborted!", data)
			})

			res.on("data", (chunk) => {
				//console.log(chunk.toString())
			})
		})

		req.setSocketKeepAlive(true, 1000)
		req.write(JSON.stringify(data))
		req.end()

		//console.log(http.globalAgent.freeSockets)

		req.on("timeout", () => {
			console.error("Compute request timed out!", data)
			resolve()
		})
	})
}

process.on("exit", shutdown)
process.on("SIGHUP", shutdown)
process.on("SIGINT", shutdown)
process.on("SIGTERM", shutdown)
process.on("uncaughtException", (error) => {
	console.log("!!Encountered an error: " + error.message)
	console.log(error.stack)
})
process.on('unhandledRejection', (error) => {
	console.log("!!Encountered a rejection: " + error.message)
	console.log(error.stack)
})

init()