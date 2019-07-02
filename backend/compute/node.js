
let database = require("./database")
let units = require("./units")
let performance = require('perf_hooks').performance
let express = require("express")
let bodyParser = require("body-parser")
let PORT = 6420;

let httpserver = express()
httpserver.use(bodyParser.json())

function shutdown(code) {
    console.log("Compute node shutting down: " + code)
    
	database.disconnect()
	process.exit(0) //Bit forceful, but we don't care, everything should be in a safe state anyway
}

function computeRequest(data) {
    console.log("Handling compute request")
    let start = performance.now()
    let statChanges = []

    for (let id in data) {
        let statChange = units.processUnit(data[id])

        if (statChange)
            statChanges.push(statChange)
    }

    let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
    console.log("Compute request took: " + timeTaken + "ms")

    return statChanges
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
    let statChanges = computeRequest(req.body)
    res.json({"statChanges":statChanges})
})

init()

process.on("exit", shutdown)
process.on("SIGHUP", shutdown)
process.on("SIGINT", shutdown)
process.on("SIGTERM", shutdown)
process.on("uncaughtException", (error) => {console.log("!!Encountered an error: " + error)})