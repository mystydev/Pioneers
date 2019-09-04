
let database = require("./database")
let units = require("./units")
let performance = require('perf_hooks').performance
let express = require("express")
let bodyParser = require("body-parser")
let PORT = 6420;

let httpserver = express()
httpserver.use(bodyParser.json({ limit: '5mb' }))

function shutdown(code) {
    console.log("Compute node shutting down: " + code)
    
	database.disconnect()
	process.exit(0) //Bit forceful, but we don't care, everything should be in a safe state anyway
}

async function computeRequest(data) {
    console.log("Handling compute request")
    let start = performance.now()
    let processing = []
    let [s, e] = data

    for (let id = s; id < e; id++)
        processing.push(units.processUnit(id))

    let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
    console.log("Compute request took: " + timeTaken + "ms")

    await Promise.all(processing)
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