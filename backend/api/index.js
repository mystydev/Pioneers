var fs = require('fs');
var https = require('https');
var Redis = require('ioredis');
var express = require("express");
var bodyParser = require('body-parser');
var redis = new Redis();
var app = express();
var privateKey  = fs.readFileSync('/certs/private.key', 'utf8');
var certificate = fs.readFileSync('/certs/public.pem', 'utf8');

var credentials = {key: privateKey, cert: certificate};
var httpsServer = https.createServer(credentials, app);

const Actions = {PLACE_TILE:0,SET_WORK:1};
//PLACE_TILE = user id, action enum, tile type enum, tile as position string
//SET_WORK   = user id, action enum, unitid, tile as position string

const PORT = 443;

app.use(bodyParser.json())

httpsServer.listen(PORT, () => {
    console.log("Pioneers HTTP API is now running on port "+PORT+"!");
});

app.post("/pion/actionRequest", (req, res) => {
    let id = req.body.id;
    let action = req.body.action;
    let tileLoc, tileType, unit;

    switch(action){
        case Actions.PLACE_TILE:
            tileType = req.body.type;
            tileLoc = req.body.position;
            redis.rpush('actionQueue', JSON.stringify({id:id, action:action, type:tileType, position:tileLoc}));
            res.json({status:"Ok"})
            break;
        case Actions.SET_WORK:
            unit = req.body.unitId;
            tileLoc = req.body.position;
            redis.rpush('actionQueue', JSON.stringify({id:id, action:action, unit:unit, position:tileLoc}))
            res.json({status:"Ok"})
            break;
        default:
            res.json({status:"Fail"})
    };
});

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

let lastProcess = 0;

async function processTimeUpdate(){
    redis.get('lastprocess').then((t) => {
        lastProcess = Math.round(t);
    });
}

setInterval(processTimeUpdate, 20);

async function waitForProcess(n) {
    while (n == lastProcess){
        await sleep(100);
    }
}

app.post("/pion/longpollunit", (req, res) => {
    waitForProcess(req.body.time).then(() => {
        redis.hgetall('units').then(units => {
            res.json({time:lastProcess, data:units});
        });
    });
});

app.post("/pion/longpolluserstats", (req, res) => {
    waitForProcess(req.body.time).then(() => {
        redis.hget('stats', req.body.userId).then(stats => {
            res.json({time:lastProcess, data:stats});
        });
    });
});

///OLD-------------------------------------------------------------------------
app.get("/pion/alltiles", (req, res) => {
    redis.hgetall('tiles').then(tiles => {
        res.json(tiles);
    });
});

app.get("/pion/allunits", (req, res) => {
    redis.hgetall('units').then(units => {
        res.json(units);
    });
})

app.post("/pion/tileupdate", (req, res) => {
    redis.hset('tiles', req.body.index, JSON.stringify(req.body.data));
    res.json({status:"ok"})
});

app.post("/pion/unitupdate", (req, res) => {
    redis.hset('units', req.body.index, JSON.stringify(req.body.data));
    res.json({status:"ok"})
});

const starterStats = {Food:500, Wood:500, Stone:500};

app.post("/pion/userjoin", (req, res) => {
    redis.hget('stats', req.body.Id).then((stats) => {
        if (stats)
            res.json(JSON.parse(stats));
        else {
            console.log("New user Id:", req.body.Id);
            let stats = {Food:500, Wood:500, Stone:500, PlayerId:req.body.Id}
            redis.hset('stats', req.body.Id, JSON.stringify(stats));
            res.json(stats);
        }
    }).catch((error) => {
        console.log("Error on userjoin:", error);
        res.json({status:"Fail"})
    })
});



//OLD----------------------------------------------------------------------------------