
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
    let response = {}
    let statChanges = []
    let damages = []
    let combats = []
    let [s, e] = data
    let unitList = await units.getRange(s, e)

    for (let id in unitList) {
        let change = await units.processUnit(unitList[id])

        if (change.Stats) {
            statChanges.push(change.Stats)
        }

        if (change.Damage) {
            damages.push(change.Damage)
        }

        if (change.InCombat) {
            combats.push(change.InCombat)
        }
    }

    let timeTaken = (performance.now() - start).toFixed(1).toString().padStart(6, " ");
    console.log("Compute request took: " + timeTaken + "ms")

    response.units = data
    response.stats = statChanges
    response.damage = damages
    response.combat = combats

    return response
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