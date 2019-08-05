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
    cluster = new Redis.Cluster([{
        port: 6379,
        host: 'redis.dev',
        retryStrategy: function(times) {
            console.error("Connection to redis lost!")
            return 1000
            },
        //reconnectOnError: function(err) {
        //    console.error("Encountered an error: " + err)
        //    console.log("Reconnecting")
        //   return true
        //   }
      }]);

    cluster.on("error", (err) => {
        console.error("Error occurred: " + err)
        //cluster.quit()
        //delete cluster
        //console.log("Attempting to reconnect to db")
        //setTimeout(connectoToRedis, 1000)
    })
}

const Actions = {NEW_PLAYER:0,PLACE_TILE:1,SET_WORK:2,ATTACK:3,DELETE_TILE:4,REPAIR_TILE:5};
//PLACE_TILE = user id, action enum, tile type enum, tile as position string
//SET_WORK   = user id, action enum, unitid, tile as position string

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

    switch(action){
        case Actions.PLACE_TILE:
            tileType = req.body.type;
            tileLoc = req.body.position;
            cluster.rpush('actionQueue', JSON.stringify({id:id, action:action, type:tileType, position:tileLoc}));
            res.json({status:"Ok"})
            break;

        case Actions.SET_WORK:
            unit = req.body.unitId;
            tileLoc = req.body.position;
            cluster.rpush('actionQueue', JSON.stringify({id:id, action:action, unit:unit, position:tileLoc}))
            res.json({status:"Ok"})
            break;

        case Actions.ATTACK:
            unit = req.body.unitId;
            tileLoc = req.body.position;
            cluster.rpush('actionQueue', JSON.stringify({id:id, action:action, unit:unit, position:tileLoc}))
            res.json({status:"Ok"})
            break;

        case Actions.DELETE_TILE:
            tileLoc = req.body.position;
            cluster.rpush('actionQueue', JSON.stringify({id:id, action:action, position:tileLoc}));
            res.json({status:"Ok"})
            break;

        case Actions.REPAIR_TILE:
            tileLoc = req.body.position;
            cluster.rpush('actionQueue', JSON.stringify({id:id, action:action, position:tileLoc}));
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

setInterval(processTimeUpdate, 20);

async function waitForProcess(n) {
    while (n == lastProcess){
        await sleep(100);
    }
}

app.post("/pion/longpollunit", (req, res) => {
    waitForProcess(req.body.time).then(() => {
        cluster.hgetall('units').then(units => {
            res.json({time:lastProcess, data:units});
        }).catch((err) => {
            console.error("Failed to get units")
            console.error(err)
        })
    }).catch((err) => {
        console.error("Failed to wait for longpoll")
        console.error(err)
    })
});

app.post("/pion/longpolluserstats", (req, res) => {
    waitForProcess(req.body.time).then(() => {
        cluster.hget('stats', req.body.userId).then(stats => {
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
})

app.post("/pion/getupdates", (req, res) => {

})

// {pos:radius, pos:radius, pos:radius...} -> {tile, tile, tile, tile...}
app.post("/pion/tileregion", (req, res) => {
    let list = req.body.list;
    let tiles = []

    for (pos in list) {
        console.log(pos, list[pos]);
        tiles = tiles.concat(getCircularRegion(pos, list[pos]));
    }

    cluster.hmget('tiles', tiles).then(collection => {
        res.json(collection);
    }).catch((err) => {
        console.error("Failed to hmget tiles")
        console.error(err)
    })
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

///OLD-------------------------------------------------------------------------
app.post("/pion/alltiles", (req, res) => {
    cluster.hgetall('tiles').then(tiles => {
        res.json(tiles);
    }).catch((err) => {
        console.error("Failed to get all tiles")
        console.error(err)
    })
});

app.post("/pion/allunits", (req, res) => {
    cluster.hgetall('units').then(units => {
        res.json(units);
    }).catch((err) => {
        console.error("Failed to get all units")
        console.error(err)
    })
})

app.post("/pion/tileupdate", (req, res) => {
    cluster.hset('tiles', req.body.index, JSON.stringify(req.body.data));
    res.json({status:"ok"})
});

app.post("/pion/unitupdate", (req, res) => {
    cluster.hset('units', req.body.index, JSON.stringify(req.body.data));
    res.json({status:"ok"})
});

app.post("/pion/userjoin", (req, res) => {
    cluster.hget('stats', req.body.Id).then((stats) => {
        if (stats)
            res.json(JSON.parse(stats));
        else {
            console.log("New user Id:", req.body.Id);
            cluster.rpush('actionQueue', JSON.stringify({id:req.body.Id, action:Actions.NEW_PLAYER}));
            res.json({status:"NewUser"});
        }
    }).catch((error) => {
        console.log("Error on userjoin:", error);
        res.json({status:"Fail"})
    })
});


process.on("uncaughtException", (error) => {
    console.log("!!Encountered an error: " + error)
    console.log("Pedantic database reconnect...")

    if (cluster)
        cluster.quit()

    setTimeout(connectoToRedis, 1000)
})

process.on('unhandledRejection', (error) => {
    console.log("!!Encountered a rejection: " + error)
    console.log("Pedantic database reconnect...")

    if (cluster)
        cluster.quit()

    setTimeout(connectoToRedis, 1000)
})

connectoToRedis()