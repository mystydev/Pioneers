let database = require("./compute/database")
let userstats = require("./compute/userstats")
let tiles = require("./compute/tiles")
let common = require("./compute/common")
var fs = require('fs');
var https = require('https');
var Redis = require('ioredis');
var express = require("express");
var bodyParser = require('body-parser');
var cors = require('cors');
var app = express();
var privateKey  = fs.readFileSync('certs/private.key', 'utf8');
var certificate = fs.readFileSync('certs/public.pem', 'utf8');
let APIKey      = fs.readFileSync("certs/apikey.key", "utf8")

var credentials = {key: privateKey, cert: certificate};
var httpsServer = https.createServer(credentials, app);

let VERSION = "1.0.6"
let cluster

function connectoToRedis() {
    cluster = database.connect()
}

const Actions = common.Actions

const PORT = 443;

app.use(cors())
app.use(bodyParser.json())

app.use(function(req, res, next) {
    if (!req.body.apikey || req.body.apikey != APIKey) {
        res.send("Invalid API key")
    } else {
        next()
    }
})

app.listen(PORT, () => {
    console.log("Pioneers HTTP API "+VERSION+" is now running on port "+PORT+"!");
});

app.get("/", (req, res) => {
    res.send("alive");
})

app.post("/pion/status", (req, res) => {
    cluster.get('status').then(s => {
        res.json(s);
    })
})

app.post("/pion/isTester", (req, res) => {
    cluster.hget('tester', req.body.id).then(s => {
        if (s) {
            res.json(s);
        } else {
            res.json("0");
        }
    }).catch((err) => {
        console.error("Failed to get tester status")
        console.error(err)
    })
})

app.post("/pion/actionRequest", (req, res) => {
    let id = req.body.id;
    let action = req.body.action;
    let tileLoc, tileType, unit;

    
    database.resetFullSimQuota(id)

    console.log(action, Actions.DELETE_KINGDOM)

    switch(action){
        case Actions.PLACE_TILE:
            tileType = req.body.type;
            tileLoc = req.body.position;
            cluster.rpush("actionQueue:"+id, JSON.stringify({id:id, action:action, type:tileType, position:tileLoc}));
            res.json({status:"Ok"})
            break;

        case Actions.SET_WORK:
            unit = req.body.unitId;
            tileLoc = req.body.position;
            cluster.rpush("actionQueue:"+id, JSON.stringify({id:id, action:action, unit:unit, position:tileLoc}))
            res.json({status:"Ok"})
            break;

        case Actions.ATTACK:
            unit = req.body.unitId;
            tileLoc = req.body.position;
            cluster.rpush("actionQueue:"+id, JSON.stringify({id:id, action:action, unit:unit, position:tileLoc}))
            res.json({status:"Ok"})
            break;

        case Actions.DELETE_TILE:
            tileLoc = req.body.position;
            cluster.rpush("actionQueue:"+id, JSON.stringify({id:id, action:action, position:tileLoc}));
            res.json({status:"Ok"})
            break;

        case Actions.REPAIR_TILE:
            tileLoc = req.body.position;
            cluster.rpush("actionQueue:"+id, JSON.stringify({id:id, action:action, position:tileLoc}));
            res.json({status:"Ok"})
            break;

        case Actions.DELETE_KINGDOM:
            cluster.rpush("actionQueue:"+id, JSON.stringify({id:id, action:action}))
            res.json({status:"Ok"})
            break;

        case Actions.SET_GUARDPOST:
            tileLoc = req.body.position
            cluster.rpush("actionQueue:"+id, JSON.stringify({id:id, action:action, position:tileLoc, set:req.body.set}))
            res.json({status:"Ok"})
            break;

        default:
            res.json({status:"Fail"})
    };
});

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function toPosition(posString) {
    var [x, y] = posString.split(":");
    return [parseInt(x), parseInt(y)];
}

function getCircularRegion(pos, radius){
    let tiles = [];
    let [x, y] = toPosition(pos);

    for (let r = 1; r <= radius; r++) {
        for (let i = 0; i <= r - 1; i++) {
            tiles.push((x +     i) + ":" + (y +     r));
            tiles.push((x +     r) + ":" + (y + r - i));
            tiles.push((x + r - i) + ":" + (y -     i));
            tiles.push((x -     i) + ":" + (y -     r));
            tiles.push((x -     r) + ":" + (y - r + i));
            tiles.push((x - r + i) + ":" + (y +     i));
        }
    }

    return tiles;
}

let lastProcess = 0;

async function processTimeUpdate(){
    cluster.get('lastprocess').then((t) => {
        lastProcess = Math.round(t);
    })
}

setInterval(processTimeUpdate, 100);

async function waitForProcess(n) {
    while (n == lastProcess){
        await sleep(100);
    }

    return true
}

app.post("/pion/longpolluserstats", (req, res) => {
    waitForProcess(req.body.time).then(() => {
        database.getStats(req.body.userId).then(stats => {
            res.json({time:lastProcess, data:stats});
        }).catch((err) => {
            console.error("Failed to get stats")
            console.error(err)
        })
    }).catch((err) => {
        console.error("Failed to wait for longpoll")
        console.error(err)
    })
});

app.post("/pion/updateinitiated", (req, res) => {
    cluster.set("lastupdate", Date.now())
    res.json("ok")
})

app.post("/pion/updatedeploying", (req, res) => {
    cluster.set("lastupdatedeploy", Date.now())
    res.json("ok")
})

app.post("/pion/syncupdates", async (req, res) => {
   
    //Push chat messages to redis
    cluster.lpush("chats", ...req.body.chats).catch(e => {})
    cluster.ltrim("chats", 0, 100)

    //Push any feedback to redis
    for (let feedback of req.body.feedback)
        cluster.lpush("feedback", feedback).catch(e => {})

    await waitForProcess(req.body.time)
    await sleep(200)

    let updates = {}
    let fetchingTiles = database.getStaleTilesFromPartitions(req.body.partitions)
    let fetchingUnits = database.getUnitsAtPartitions(req.body.partitions)
    let lastProcess = cluster.get("lastprocess")
    let lastUpdate  = cluster.get("lastupdate")
    let lastDeploy  = cluster.get("lastupdatedeploy")
    let chats       = cluster.lrange("chats", 0, 100)
    let guardposts  = true

    if (req.body.playerlist)
        guardposts = database.getGuardpostsFromList(req.body.playerlist)

    //Wait for redis to return all the data
    Promise.all([fetchingTiles, fetchingUnits, lastProcess, lastUpdate, lastDeploy, chats, guardposts])
    .then(values => {
        updates.partitions  = values[0];
        updates.units       = values[1];
        updates.lastProcess = values[2]; //last round processed
        updates.lastUpdate  = values[3]; //last time an update was issued
        updates.lastDeploy  = values[4]; //last time the update redeployed instances in kubernetes
        updates.chats       = values[5];
        updates.guardposts  = values[6];
        res.json(updates)
    })

    database.clearCaches()
})

app.post("/pion/getPartitionOwners", async (req, res) => {

    let partitionList = []

    for (let x = req.body.x - 200; x < req.body.x + 200; x += 20) //TODO: use partition size not 20
        for (let y = req.body.y - 200; y < req.body.y + 200; y += 20)
            partitionList.push(database.findPartitionId(x+":"+y))

    let ownerMap = await database.getOwnersOfPartitions(partitionList)
    let keepMap = {}

    for (let partitionId in ownerMap) {
        let owner = ownerMap[partitionId]

        if (!keepMap[owner])
            keepMap[owner] = await userstats.getKeep(owner)
    }

    res.json({owner: ownerMap, keep: keepMap})
})

app.post("/pion/getusersettings", (req, res) => {
    cluster.hget("settings", req.body.Id).then((settings) => {
        if (settings) {
            res.json(JSON.parse(settings))
        } else {
            settings = {
                ShowDevelopmentWarning: true,
                DismissedTutorial: false,
            }
            console.log("New user settings: ", req.body.Id)
            cluster.hset("settings", req.body.Id, JSON.stringify(settings))
            res.json(settings)
        }

    }).catch((err) => {
        console.error("Failed to get settings")
        console.error(err)
    })
})

app.post("/pion/updateusersettings", (req, res) => {
    let settings = req.body.Settings

    //protected settings checks

    cluster.hset("settings", req.body.Id, JSON.stringify(settings))
    res.json(settings)
})

app.post("/pion/userjoin", (req, res) => {
    database.getStats(req.body.Id).then((stats) => {
        if (stats.Food != undefined) {
            res.json(stats)
        } else {
            stats = userstats.newPlayer(req.body.Id)
            res.json({status:"NewUser", stats:stats})
        }
    }).catch((error) => {
        console.log("Error on userjoin:", error)
        res.json({status:"Fail"})
    })
});

app.post("/pion/getgamesettings", (req, res) => {
    let settings = {}

    settings.level_requirements = common.level_requirements
    settings.MAX_STORAGE_DIST = common.MAX_STORAGE_DIST

    res.json(settings)
})


process.on("uncaughtException", (error) => {
    console.log("!!Encountered an error: " + error)
    console.log("Pedantic database reconnect...")

    if (cluster)
        cluster.quit().catch(e => {})

    setTimeout(connectoToRedis, 1000)
    //console.log("Pedantic pod termination")
    //process.exit(1)
})

process.on('unhandledRejection', (error, promise) => {
    console.log("!!Encountered a rejection: " + error)
    console.log(promise)
})

connectoToRedis()