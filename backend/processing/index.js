const process = require('process');
var performance = require('perf_hooks').performance;
var SortedSet = require("collections/sorted-set");
var Redis = require('ioredis');
var redis = new Redis();

const MAX_FATIGUE = 10
const SPAWN_TIME = 10
const TileType = {GRASS:0,KEEP:1,PATH:2,HOUSE:3,FARM:4,MINE:5,FORESTRY:6,STORAGE:7,BARRACKS:8,WALL:9,GATE:10};
const UnitType = {NONE:0,VILLAGER:1,SOLDIER:2};
const UnitState = {IDLE:0, DEAD:1, MOVING:2, WORKING:3, RESTING:4, STORING:5};
const ResourceType = {FOOD:"Food", WOOD:"Wood", STONE:"Stone"};
const Actions = {PLACE_TILE:0,SET_WORK:1};
//PLACE_TILE = user id, action enum, tile type enum, tile as position string
//SET_WORK   = user id, action enum, unitid, tile as position string

const DefaultTile = [
    {}, //GRASS
    {Type:TileType.KEEP, Health:1000},
    {Type:TileType.PATH, Health:100},
    {Type:TileType.HOUSE, Health:200},
    {Type:TileType.FARM, Health:100},
    {Type:TileType.MINE, Health:100},
    {Type:TileType.FORESTRY, Health:100},
    {Type:TileType.STORAGE, Health:300},
]

Tiles = {};
Units = {};
UserStats = {};
UnitCount = 0;

async function fetchRedisData(){
    tiles = await redis.hgetall('tiles');

    let num = 0
    for (key in tiles) {
        Tiles[key] = JSON.parse(tiles[key]);
        num++;
    }
    console.log("Loaded", num, "tiles!");

    units = await redis.hgetall('units');
    num = 0
    for (key in units) {
        Units[key] = JSON.parse(units[key]);
        num++;
    }
    console.log("Loaded", num, "units!");

    stats = await redis.hgetall('stats');
    num = 0
    for (key in stats) {
        UserStats[key] = JSON.parse(stats[key]);
        num++;
    }
    console.log("Loaded", num, "stats!");

    UnitCount = await redis.get('unitcount');

    if (!UnitCount){
        UnitCount = 1;
    }
}

function verifyTilePlacement(redispipe, id, position, type){
    let tile = Tiles[position];
    
    if (tile == undefined){ //If the tile is grass TODO:Full verification
        
        tile = JSON.parse(JSON.stringify(DefaultTile[type]));
        tile.OwnerId = id;

        Tiles[position] = tile;
        redispipe.hset('tiles', position, JSON.stringify(tile));

        if (type == TileType.HOUSE){
            redispipe.rpush('needsunits', JSON.stringify({p:position, i:0}));
        }
    }
}

function verifyWorkAssignment(redispipe, id, unitid, position){
    let unit = Units[unitid];
    let tile = Tiles[position];

    if (unit && tile && unit.OwnerId == id && tile.OwnerId == id){
        unit.Work = position;
        unit.Target = position;
        redispipe.hset('units', unitid, JSON.stringify(unit));
    }
}

async function processActionQueue(redispipe){
    let actions = await redis.lrange('actionQueue', 0, -1);
    redis.ltrim('actionQueue', actions.length, -1);

    //process.stdout.write(actions.length + " actions ");
    for (index in actions) {
        let action = JSON.parse(actions[index]);

        switch(action.action){
            case Actions.PLACE_TILE:
                verifyTilePlacement(redispipe, action.id, action.position, action.type);
                break;
            case Actions.SET_WORK:
                verifyWorkAssignment(redispipe, action.id, action.unit, action.position);
                break;
            default:
                console.log("Unknown action!", action);
        }
    }

    return actions.length
}

function addResource(id, resource){
    var stats = UserStats[id];

    if (!stats){
        console.warn("Attempted to alter unknown users stats:", id, resource);
        return;
    }

    stats[resource.Type] += resource.Amount;
    redis.hset('stats', id, JSON.stringify(stats));
}

function useResource(id, resource){
    var stats = UserStats[id];

    if (!stats){
        console.warn("Attempted to alter unknown users stats:", id, resource);
        return;
    }

    stats[resource.Type] -= resource.Amount;
    redis.hset('stats', id, JSON.stringify(stats));
}

function getTileOutput(pos){
    var tile = getTile(pos);

    if (tile)
        switch (tile.Type){
            case TileType.FARM:
                return {Type: ResourceType.FOOD, Amount: 1};
            case TileType.MINE:
                return {Type: ResourceType.STONE, Amount: 1};
            case TileType.FORESTRY:
                return {Type: ResourceType.WOOD, Amount: 1};
            default:
                return false;
        }
}

function addProduceToUnit(unit, produce){
    var held = unit.HeldResource;

    if (!held || unit.HeldResource.Type != produce.Type)
        unit.HeldResource = produce;
    else
        unit.HeldResource.Amount += produce.Amount;
}

function getTile(x, y) {
    return Tiles[x+":"+y];
}

function getTile(pos) {
    return Tiles[pos];
}

function safeType(pos){
    var Tile = Tiles[pos];

    return Tile ? Tile.Type : TileType.GRASS;
}

function toPosition(posString) {
    var [x, y] = posString.split(":");
    return [parseInt(x), parseInt(y)];
}

function fCompare(obj1, obj2){
    let val = obj1.f - obj2.f
    return val != 0 ? val : -1;
}

function openSetEquals(obj1, obj2){
    return obj1.p == obj2.p;
}

function getNeighbours(tile){
    var [x, y] = toPosition(tile);

    return [
        (x    ) + ":" + (y + 1),
        (x + 1) + ":" + (y + 1),
        (x + 1) + ":" + (y    ),
        (x    ) + ":" + (y - 1),
        (x - 1) + ":" + (y - 1),
        (x - 1) + ":" + (y    )
    ]
}

function costHeuristic(start, end){
    var [sx, sy] = toPosition(start);
    var [ex, ey] = toPosition(end);

    var dx = ex - sx;
    var dy = ey - sy;

    if (Math.sign(dx) != Math.sign(dy))
        return Math.abs(dx) + Math.abs(dy);
    else
        return Math.max(Math.abs(dx), Math.abs(dy));
}


function reconstructPath(start, end, cameFrom){
    var path = []
    var current = end

    while (current != start) {
        path.unshift(current);
        current = cameFrom[current];
    }

    return path;
}

function getMin(set){
    let min = 999999;
    let minV, index;

    for (i in set) {
        let c = set[i];

        if (c.f < min){
            min = c.f;
            minV = c;
            index = i;
        }
    }

    return [index, minV];
}

//A* implementation
function findPath(start, target) {
    var openSet = [];
    var closedSet = new Set();
    var cameFrom = {};
    var gScore = {};
    var iterations = 0;

    openSet.push({p:start,f:0});
    gScore[start] = 0;

    while (iterations++ < 1000) {
        //var current = openSet.min();
        let [ind, current] = getMin(openSet);

        if (!current) {
            console.log("Unable to get min from openset!"); 
            return;
        }

        openSet.splice(ind, 1);

        //if (!openSet.remove(current)) return false;
        if (current.p == target) {
            return reconstructPath(start, target, cameFrom);
        }

        closedSet.add(current)

        var neighbours = getNeighbours(current.p)

        for (var n in neighbours){
            var neighbour = neighbours[n];

            if (closedSet.has(neighbour)) continue;
            if ((!getTile(neighbour) || getTile(neighbour).Type != TileType.PATH) && neighbour != target) continue;
            if (!gScore[neighbour]) gScore[neighbour] = Infinity;

            var g = gScore[current.p] + 1

            if (g < gScore[neighbour]) {
                gScore[neighbour] = g
                cameFrom[neighbour] = current.p;
                openSet.push({p:neighbour, f:(g + costHeuristic(neighbour, target))});
            }
        }
    }

    console.warn("Aborted path that explored too far!");
}   

function findClosestStorage(pos) {
    var searchQueue = [pos];
    var current;
    let index = 0;

    while (current = searchQueue[index++]){
        let neighbours = getNeighbours(current);
        let checked    = new Set();
        let neighbour, type;

        for (let i in neighbours) {

            neighbour = neighbours[i];

            if (checked.has(neighbour)) continue;

            type = safeType(neighbour);

            if (type == TileType.STORAGE || type == TileType.KEEP){
                return neighbour;
            }else if (type == TileType.PATH) {
                searchQueue.push(neighbour);
                checked.add(neighbour);
            }
        }
    }
}

function establishUnitState(unit) {
    var pos = unit.Posx +":"+ unit.Posy;
    var hasHome = unit.Home;
    var hasWork = unit.Work;
    var hasTarget = unit.Target;
    var hasResource = unit.HeldResource;
    var atHome = pos == hasHome;
    var atWork = pos == hasWork;
    var atTarget = pos == hasTarget;
    
    if (unit.Health == 0)
        return [UnitState.DEAD, pos, hasTarget];

    else if (hasTarget && !atTarget)
        return [UnitState.MOVING, pos, hasTarget];

    else if (unit.Fatigue < MAX_FATIGUE && atWork)
        return [UnitState.WORKING, pos, hasWork];

    else if (hasResource) 
        return [UnitState.STORING, pos, hasTarget];

    else if (unit.Fatigue > 0 && atHome)
        return [UnitState.RESTING, pos, hasTarget];

    else
        return [UnitState.IDLE, pos, hasTarget];
}  

function spawnUnit(redispipe, position){

    let tile = Tiles[position];
    let id = UnitCount++
    let [x, y] = toPosition(position)

    let unit = {
        Type:1,
        Id:id,
        OwnerId:tile.OwnerId,
        Posx:x,
        Posy:y,
        Health:200,
        Fatigue:0,
        Home:position,
    };

    Units[id] = unit;
    redispipe.hset('units', id, JSON.stringify(unit));
    redispipe.set('unitcount', UnitCount);
}

async function processUnitSpawns(redispipe){
    let spawns = await redis.lrange('needsunits', 0, -1); //TODO: read cache and send updates back
    redis.ltrim('needsunits', spawns.length, -1);

    for (index in spawns) {
        let spawn = JSON.parse(spawns[index]);

        if (spawn.i < SPAWN_TIME){
            redispipe.rpush('needsunits', JSON.stringify({p:spawn.p,i:(spawn.i+1)}));
        } else {
            spawnUnit(redispipe, spawn.p); //TODO: Fix this more!
            spawnUnit(redispipe, spawn.p);
        }
    }
}

async function processRound() {
    var t1 = performance.now();
    var processed = 0;
    let redispipe = redis.pipeline();

    let pactions = await processActionQueue(redispipe);

    var t2 = performance.now();
    //process.stdout.write(Math.round((t2 - t1)*100)/100 + " ms/");

    await processUnitSpawns(redispipe);

    var t3 = performance.now();
    //process.stdout.write("spawns " + Math.round((t3 - t2)*100)/100 + " ms/");

    for (var id in Units){
        processed++;
        var unit = Units[id];
        var [state, pos, target] = establishUnitState(unit)

        unit.State = state;

        switch(state){
            case UnitState.MOVING:
                var path = findPath(pos, target);
                if (!path) {console.warn("Unit could not find a path!");return;}
                [unit.Posx, unit.Posy] = toPosition(path[0]);
                break;

            case UnitState.WORKING:
                var produce = getTileOutput(pos);
                addProduceToUnit(unit, produce)
                if (unit.Fatigue++ >= MAX_FATIGUE)
                    unit.Target = findClosestStorage(pos);
                break;

            case UnitState.RESTING:
                useResource(unit.OwnerId, {Type:ResourceType.FOOD,Amount:5});

                unit.Fatigue -= 5;

                if (unit.Fatigue <= 0) {
                    unit.Fatigue = 0;
                    unit.Target = unit.Work;
                }
                break;

            case UnitState.STORING:
                var t = safeType(pos);

                if (t == TileType.STORAGE || t == TileType.KEEP){
                    addResource(unit.OwnerId, unit.HeldResource);
                    unit.HeldResource = undefined;

                    if (unit.Fatigue > 0)
                        unit.Target = unit.Home;
                } else {
                    unit.Target = findClosestStorage(pos);
                }
                break;
        }

        redispipe.hset('units', id, JSON.stringify(unit));
    }

    var t4 = performance.now();
    //process.stdout.write(processed + " units " + Math.round((t4 - t3)*100)/100 + " ms/");

    redispipe.exec((err, results) => {
        if (err) console.warn("Error executing redis pipeline! ", err);
    });

    var t5 = performance.now();
    //process.stdout.write("Redis " + Math.round((t5 - t4)*100)/100 + " ms/");
    //process.stdout.write("Total:" + Math.round((t5 - t1)*100)/100 + "ms\r");

    let atime = (t2 - t1).toFixed(1).toString().padStart(3, " ");
    let stime = (t3 - t2).toFixed(1).toString().padStart(3, " ");
    let utime = (t4 - t3).toFixed(1).toString().padStart(6, " ");
    let rtime = (t5 - t4).toFixed(1).toString().padStart(3, " ");
    let ttime = (t5 - t1).toFixed(1).toString().padStart(6, " ");

    let outInfo = `Total: ${ttime}ms (${pactions} actions ${atime}, ${processed} units ${utime}, redis ${rtime}, spawn ${stime})`;
    console.log(outInfo);

    redis.set('lastprocess', Math.round(t5));
}

console.log("Pioneers processing backend starting....");
fetchRedisData();
setInterval(processRound, 2000);
