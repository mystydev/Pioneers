//var fs = require('fs');
//var https = require('https');
var Redis = require('ioredis');
var express = require("express");
var bodyParser = require('body-parser');
var redis = new Redis();
var app = express();
//var privateKey  = fs.readFileSync('/certs/private.key', 'utf8');
//var certificate = fs.readFileSync('/certs/public.pem', 'utf8');

//var credentials = {key: privateKey, cert: certificate};
//var httpsServer = https.createServer(credentials, app);

const PORT = 3000;

app.use(bodyParser.json())

app.listen(PORT, () => {
    console.log("Pioneers HTTP API is now running on port "+PORT+"!");
});

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