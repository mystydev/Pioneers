const process = require('process');
var performance = require('perf_hooks').performance;
var SortedSet = require("collections/sorted-set");
var Redis = require('ioredis');
var redis = new Redis();

const STARTING_FOOD = 1000;
const STARTING_WOOD = 2500;
const STARTING_STONE = 2500;
const MAX_FATIGUE = 10;
const HOUSE_UNIT_NUMBER = 2;
const SPAWN_TIME = 10;
const SPAWN_REQUIRED_FOOD = 100;
const MAX_STORAGE_DIST = 15;
const MAX_PATH_LENGTH = 15;
const TileType = {DESTROYED:-1,GRASS:0,KEEP:1,PATH:2,HOUSE:3,FARM:4,MINE:5,FORESTRY:6,STORAGE:7,BARRACKS:8,WALL:9,GATE:10};
const UnitType = {NONE:0,VILLAGER:1,FARMER:2,LUMBERJACK:3,MINER:4, APPRENTICE:5, SOLDIER:6};
const UnitState = {IDLE:0, DEAD:1, MOVING:2, WORKING:3, RESTING:4, STORING:5, COMBAT:6, LOST:7};
const ResourceType = {FOOD:"Food", WOOD:"Wood", STONE:"Stone"};
const Actions = {NEW_PLAYER:0,PLACE_TILE:1,SET_WORK:2,ATTACK:3,DELETE_TILE:4};
//PLACE_TILE = user id, action enum, tile type enum, tile as position string
//SET_WORK   = user id, action enum, unitid, tile as position string
//NEW_PLAYER = user id, action enum, playerid

const TileConstructionCosts = {}
TileConstructionCosts[TileType.KEEP]     = {Stone:0,     Wood:0};
TileConstructionCosts[TileType.PATH]     = {Stone:20,    Wood:0};
TileConstructionCosts[TileType.HOUSE]    = {Stone:100,   Wood:100};
TileConstructionCosts[TileType.FARM]     = {Stone:75,    Wood:75};
TileConstructionCosts[TileType.MINE]     = {Stone:0,     Wood:150};
TileConstructionCosts[TileType.FORESTRY] = {Stone:150,   Wood:0};
TileConstructionCosts[TileType.STORAGE]  = {Stone:500,   Wood:500};
TileConstructionCosts[TileType.BARRACKS] = {Stone:500,   Wood:300};
TileConstructionCosts[TileType.WALL]     = {Stone:1000,  Wood:1000};
TileConstructionCosts[TileType.GATE]     = {Stone:1000,  Wood:1500};

const TileMaintenanceCosts = {}
TileMaintenanceCosts[TileType.KEEP]     = {Stone:0,     Wood:0};
TileMaintenanceCosts[TileType.PATH]     = {Stone:.1,    Wood:.1};
TileMaintenanceCosts[TileType.HOUSE]    = {Stone:.5,    Wood:.5};
TileMaintenanceCosts[TileType.FARM]     = {Stone:.33,   Wood:.33};
TileMaintenanceCosts[TileType.MINE]     = {Stone:0,     Wood:.5};
TileMaintenanceCosts[TileType.FORESTRY] = {Stone:.5,    Wood:0};
TileMaintenanceCosts[TileType.STORAGE]  = {Stone:1,     Wood:1};
TileMaintenanceCosts[TileType.BARRACKS] = {Stone:2,     Wood:2};
TileMaintenanceCosts[TileType.WALL]     = {Stone:3,     Wood:3};
TileMaintenanceCosts[TileType.GATE]     = {Stone:3,     Wood:3};

const DefaultTile = [
    {}, //GRASS
    {Type:TileType.KEEP, Health:1000},
    {Type:TileType.PATH, Health:100},
    {Type:TileType.HOUSE, Health:200, unitlist:[]},
    {Type:TileType.FARM, Health:100, unitlist:[]},
    {Type:TileType.MINE, Health:100, unitlist:[]},
    {Type:TileType.FORESTRY, Health:100, unitlist:[]},
    {Type:TileType.STORAGE, Health:300},
    {Type:TileType.BARRACKS, Health:1000, unitlist:[]},
    {Type:TileType.WALL, Health:10000},
    {Type:TileType.GATE, Health:10000},
]

let Tiles = {};
let Units = {};
let UserStats = {};
let UnitCount = 0;
let UnitSpawns = {};

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

    spawns = await redis.get('unitspawns');

    num = 0
    for (pos in spawns) {
        UnitSpawns[pos] = JSON.parse(spawns[pos]);
        num++;
    }
    console.log("Loaded", num, "spawns!");

    if (!UnitCount){
        UnitCount = 1;
    }
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

function makeDefaultTile() {
    return {Type:TileType.GRASS, unitlist:[]};
}

function addResource(id, resource, redispipe){
    var stats = UserStats[id];

    if (!stats){
        console.warn("Attempted to alter unknown users stats:", id, resource);
        return;
    }

    stats[resource.Type] += resource.Amount;
    //redispipe.hset('stats', id, JSON.stringify(stats));
}

function useResource(id, resource, redispipe){
    var stats = UserStats[id];

    if (!stats){
        console.warn("Attempted to alter unknown users stats:", id, resource);
        return;
    }

    stats[resource.Type] -= resource.Amount;
    //redispipe.hset('stats', id, JSON.stringify(stats));
}

function canBuild(id, tile, position, type){

    if (tile && (tile.Type != TileType.GRASS || tile.unitlist.length > 0)){
        return false;
    }

    let stats = UserStats[id];
    let req = TileConstructionCosts[type];

    for (res in req) 
        if (stats[res] < req[res])
            return false;

    let neighbours = getNeighbours(position);
    let hasTile = false
    
    if (type == TileType.KEEP)
        return true;

    for (n in neighbours){
        let t = safeType(neighbours[n])
        if (t == TileType.PATH || t == TileType.GATE)
            hasTile = true;
    }

    return hasTile;
}

function isMilitary(unitType){
    return unitType >= UnitType.APPRENTICE && unitType <= UnitType.SOLDIER;
}

function isWalkable(position, unit){
    let type = safeType(position)

    if (type == TileType.PATH || type == TileType.GATE) return true;
    else if (type == TileType.GRASS && isMilitary(unit.Type)) return true;
}

function verifyTilePlacement(redispipe, id, position, type){
    let tile = Tiles[position];
    
    if (canBuild(id, tile, position, type)){
        
        let req = TileConstructionCosts[type];

        for (res in req){
            useResource(id, {Type:res, Amount:req[res]}, redispipe);
        }

        tile = JSON.parse(JSON.stringify(DefaultTile[type]));
        tile.OwnerId = id;

        Tiles[position] = tile;
        redispipe.hset('tiles', position, JSON.stringify(tile));

        UserStats[id].MWood += TileMaintenanceCosts[type].Wood;
        UserStats[id].MStone += TileMaintenanceCosts[type].Stone;
        redispipe.hset('stats', id, JSON.stringify(UserStats[id]));

        if (type == TileType.HOUSE){
            redispipe.hset('unitspawns', position, 0);
            UnitSpawns[position] = 0;
        }

        if (type == TileType.KEEP){
            let neighbours = getNeighbours(position);
            
            for (i in neighbours) {
                let pos = neighbours[i]
                let t = JSON.parse(JSON.stringify(DefaultTile[TileType.PATH]));
                t.OwnerId = id;

                Tiles[pos] = t;
                redispipe.hset('tiles', pos, JSON.stringify(t));
            }
        }
    }
}

function verifyAttackAssignment(redispipe, id, unitid, position){
    
    let unit = Units[unitid];
    let tile = Tiles[position];

    if (!unit || !tile) return;
    if (tile.unitlist.length > 0) {

    }
    if (!(tile.unitlist && tile.unitlist.length > 0) && tile.Type == TileType.GRASS) return;
    if (costHeuristic(unit.Posx+":"+unit.Posy, position) != 1) {console.log("Attack target too far!", costHeuristic(unit.Posx+":"+unit.Posy, position), unit.Posx+":"+unit.Posy, position); return}
    unit.Attack = position;
    console.log(unit.Attack, Units[unitid]);
    redispipe.hset('units', unitid, JSON.stringify(unit));
}

function verifyWorkAssignment(redispipe, id, unitid, position){

    let unit = Units[unitid];
    let tile = Tiles[position];
    if (!tile) tile = makeDefaultTile();

    if (unit && unit.OwnerId == id && tile.unitlist.length == 0){

        let assigned = true;

        if (!isMilitary(unit.Type) && tile.OwnerId == id){
            switch (tile.Type){

                case TileType.FARM:
                    unit.Type = UnitType.FARMER;
                    break;
                case TileType.FORESTRY:
                    unit.Type = UnitType.LUMBERJACK;
                    break;                
                case TileType.MINE:
                    unit.Type = UnitType.MINER;
                    break;                
                case TileType.BARRACKS:
                    unit.Type = UnitType.APPRENTICE;
                    if (!unit.Training) unit.Training = 0;
                    break;
                default:
                    assigned = false;
            }
        } else if (isMilitary(unit.Type)) {
            switch (tile.Type){
                case TileType.GRASS:
                    break;
                case TileType.BARRACKS:
                    break;
                default:
                    assigned = false;
            }
        } else {
            assigned = false;
        }

        if (assigned) {

            if (unit.Work && Tiles[unit.Work]) {
                let work = Tiles[unit.Work];
                work.unitlist = [];
                redispipe.hset('tiles', unit.Work, JSON.stringify(work));
            }
            
            Tiles[position] = tile;
            unit.Work = position;
            unit.Target = position;
            delete unit.Attack;
            
            tile.unitlist.push(unit.Id);
            redispipe.hset('tiles', position, JSON.stringify(tile));      
            redispipe.hset('units', unitid, JSON.stringify(unit));
        }
    }
}

function deleteTile(redispipe, id, position){
    let tile = Tiles[position];

    if (tile && (!tile.unitlist || tile.unitlist.length == 0)){
        UserStats[id].MWood -= TileMaintenanceCosts[tile.Type].Wood;
        UserStats[id].MStone -= TileMaintenanceCosts[tile.Type].Stone;
        redispipe.hset('stats', id, JSON.stringify(UserStats[id]));

        Tiles[position] = makeDefaultTile();
        redispipe.hset('tiles', position, JSON.stringify(Tiles[position]));
    }
}  

function verifyTileDelete(redispipe, id, position){
    deleteTile(redispipe, id, position)
}

function handleNewPlayer(redispipe, id){
    let stats = {Food:STARTING_FOOD, Wood:STARTING_WOOD, Stone:STARTING_STONE, PlayerId:id, MFood:0,MWood:0,MStone:0};
    UserStats[id] = stats;
    redispipe.hset('stats', id, JSON.stringify(stats));
}

async function processActionQueue(redispipe){
    let actions = await redis.lrange('actionQueue', 0, -1);
    redis.ltrim('actionQueue', actions.length, -1);

    //process.stdout.write(actions.length + " actions ");
    for (index in actions) {
        let action = JSON.parse(actions[index]);

        switch(action.action){

            case Actions.NEW_PLAYER:
                handleNewPlayer(redispipe, action.id);
                break;
            case Actions.PLACE_TILE:
                verifyTilePlacement(redispipe, action.id, action.position, action.type);
                break;
            case Actions.SET_WORK:
                verifyWorkAssignment(redispipe, action.id, action.unit, action.position);
                break;
            case Actions.ATTACK:
                verifyAttackAssignment(redispipe, action.id, action.unit, action.position);
                break;
            case Actions.DELETE_TILE:
                verifyTileDelete(redispipe, action.id, action.position);
                break;
            default:
                console.log("Unknown action!", action);
        }
    }

    return actions.length
}

function getTileOutput(pos){
    let tile = getTile(pos);
    let neighbours = getNeighbours(pos);

    let produce = 6;

    for (n in neighbours) {
        let neighbour = getTile(neighbours[n]);

        if (neighbour && neighbour.Type == tile.Type)
            produce++;
    }

    if (tile)
        switch (tile.Type){
            case TileType.FARM:
                return {Type: ResourceType.FOOD, Amount: produce};
            case TileType.MINE:
                return {Type: ResourceType.STONE, Amount: produce};
            case TileType.FORESTRY:
                return {Type: ResourceType.WOOD, Amount: produce};
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

function fCompare(obj1, obj2){
    let val = obj1.f - obj2.f
    return val != 0 ? val : -1;
}

function openSetEquals(obj1, obj2){
    return obj1.p == obj2.p;
}

function getNeighbours(pos){
    var [x, y] = toPosition(pos);

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
        path.unshift(current); //TODO: perf test
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
function findPath(start, target, unit) {
    var openSet = [];
    var closedSet = new Set();
    var cameFrom = {};
    var gScore = {};
    var iterations = 0;

    openSet.push({p:start,f:0});
    gScore[start] = 0;

    while (iterations++ < 1000) {
        let [ind, current] = getMin(openSet);

        openSet.splice(ind, 1);

        if (!current) return;

        if (current.p == target) {
            return reconstructPath(start, target, cameFrom);
        }

        closedSet.add(current)

        var neighbours = getNeighbours(current.p)

        for (var n in neighbours){
            var neighbour = neighbours[n];

            if (closedSet.has(neighbour)) continue;
            if ((!isWalkable(neighbour, unit)) && neighbour != target) continue;
            if (!gScore[neighbour]) gScore[neighbour] = Infinity;

            var g = gScore[current.p] + 1

            if (g < MAX_PATH_LENGTH && g < gScore[neighbour]) {
                gScore[neighbour] = g
                cameFrom[neighbour] = current.p;
                openSet.push({p:neighbour, f:(g + costHeuristic(neighbour, target))});
            }
        }
    }

    //console.warn("Aborted path that explored too far!");
}   

function findClosestStorage(pos) {
    var searchQueue = [pos];
    var current;
    let index = 0;
    let distance = {}
    distance[pos] = 0;

    while (current = searchQueue[index++]){
        let neighbours = getNeighbours(current);
        let checked    = new Set();
        let neighbour, type;

        for (let i in neighbours) {

            neighbour = neighbours[i];
            let dist = distance[current] + 1;

            if (!distance[neighbour] || distance[neighbour] > dist){
                distance[neighbour] = dist;
            }
            
            if (checked.has(neighbour) || distance[neighbour] > MAX_STORAGE_DIST) continue;
            
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
    var hasResource = unit.HeldResource && unit.HeldResource.Amount > 0;
    var atHome = pos == hasHome;
    var atWork = pos == hasWork;
    var atTarget = pos == hasTarget;

    if (unit.Health == 0)
        return [UnitState.DEAD, pos, hasTarget];

    else if (unit.Attack)
        return [UnitState.COMBAT, pos, hasTarget];

    else if (hasTarget && !atTarget)
        return [UnitState.MOVING, pos, hasTarget];

    else if (atWork)
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
    let id = (UnitCount++).toString()
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
    useResource(unit.OwnerId, {Type:ResourceType.FOOD,Amount:100}, redispipe);
    redispipe.hset('units', id, JSON.stringify(unit));
    redispipe.set('unitcount', UnitCount);

    return unit;
}

async function processUnitSpawns(redispipe){

    for (pos in UnitSpawns) {
        let tile = getTile(pos);
        let checkNum = UnitSpawns[pos];

        if (UserStats[tile.OwnerId][ResourceType.FOOD] < SPAWN_REQUIRED_FOOD) continue;

        if (checkNum < SPAWN_TIME) {
            UnitSpawns[pos]++;
        } else {
            let unit = spawnUnit(redispipe, pos);
            tile.unitlist.push(unit.Id);

            redispipe.hset('tiles', pos, JSON.stringify(tile))

            if (tile.unitlist.length >= HOUSE_UNIT_NUMBER) {
                delete UnitSpawns[pos];
                redispipe.hdel('unitspawns', pos);
            } else {
                UnitSpawns[pos] = 0;
                redispipe.hset('unitspawns', pos, UnitSpawns[pos])
            }
        }
    }
}

async function processRound() {
    var t1 = performance.now();
    var processed = 0;
    let redispipe = redis.pipeline();

    let pactions = await processActionQueue(redispipe);

    var t2 = performance.now();

    await processUnitSpawns(redispipe);

    for (id in UserStats){
        let stats = UserStats[id]
        stats.Wood -= stats.MWood;
        stats.Stone -= stats.MStone;
    }

    var t3 = performance.now();

    for (var id in Units){
        processed++;
        var unit = Units[id];
        var [state, pos, target] = establishUnitState(unit)

        unit.State = state;

        switch(state){
            case UnitState.MOVING:
                var path = findPath(pos, target, unit);
                if (!path) {unit.State = UnitState.LOST; console.log("Unit lost due to no path"); break;}
                [unit.Posx, unit.Posy] = toPosition(path[0]);
                break;

            case UnitState.COMBAT:

                let attacked = getTile(unit.Attack)

                if (!attacked) {
                    delete unit.Attack;
                    break;
                }

                let list = attacked.unitlist;

                if (list && list.length > 0 && isMilitary(list[0].Type)){
                    list[0].Health -= 1;
                    list[0].Work = list[1].Position;
                    list[0].Attack = pos;
                    
                    if (list[0].Health <= 0) list[0].State = UnitState.DEAD;
                    redispipe.hset('units', id, JSON.stringify(unit));

                } else {
                    
                    attacked.Health -= 1;
                    redispipe.hset('tiles', unit.Attack, JSON.stringify(attacked));

                    if (attacked.Health <= 0){
                        attacked.Type = TileType.DESTROYED;
                        delete unit.Attack;
                    }
                }
                break;

            case UnitState.WORKING:

                if (isMilitary(unit.Type)) {

                    unit.Training++;

                    if (unit.Training > 10) {
                        unit.Type = UnitType.SOLDIER;
                    }

                    unit.Fatigue += 0.1;
                    if (unit.Fatigue >= MAX_FATIGUE)
                        unit.Target = findClosestStorage(pos);

                } else {
                    var produce = getTileOutput(pos);
                    addProduceToUnit(unit, produce)

                    unit.Fatigue++

                    if (unit.Fatigue >= MAX_FATIGUE)
                        unit.Target = findClosestStorage(pos);
                }

                if (!unit.Target) {
                    unit.State = UnitState.LOST;
                    console.log("Unit lost due to no found storage");
                }

                break;

            case UnitState.RESTING:
                useResource(unit.OwnerId, {Type:ResourceType.FOOD,Amount:10}, redispipe);

                unit.Fatigue -= 5;

                if (unit.Fatigue <= 0) {
                    unit.Fatigue = 0;
                    unit.Target = unit.Work;
                }
                break;

            case UnitState.STORING:
                var t = safeType(pos);

                if (t == TileType.STORAGE || t == TileType.KEEP){
                    addResource(unit.OwnerId, unit.HeldResource, redispipe);
                    unit.HeldResource = undefined;

                    if (unit.Fatigue > 0)
                        unit.Target = unit.Home;
                } else {
                    unit.Target = findClosestStorage(pos);

                    if (!unit.Target) unit.State = UnitState.LOST;
                }
                break;

            case UnitState.IDLE:
                unit.Target = unit.Home;
                break;
        }

        redispipe.hset('units', id, JSON.stringify(unit));
    }

    var t4 = performance.now();

    for (id in UserStats) {
        let stats = UserStats[id];
        redispipe.hset('stats', id, JSON.stringify(stats));
    }

    redispipe.exec((err, results) => {
        if (err) console.warn("Error executing redis pipeline! ", err);
    });

    var t5 = performance.now();

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
