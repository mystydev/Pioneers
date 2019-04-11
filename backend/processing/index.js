var performance = require('perf_hooks').performance;
var SortedSet = require("collections/sorted-set");
var Redis = require('ioredis');
var redis = new Redis();

const MAX_FATIGUE = 10
const TileType = {GRASS:0,KEEP:1,PATH:2,HOUSE:3,FARM:4,MINE:5,FORESTRY:6,STORAGE:7,BARRACKS:8,WALL:9,GATE:10};
const UnitType = {NONE:0,VILLAGER:1,SOLDIER:2};
const UnitState = {IDLE:0, DEAD:1, MOVING:2, WORKING:3, RESTING:4, STORING:5};
const ResourceType = {FOOD:0, WOOD:1, STONE:2};

Tiles = {};
Units = {};
UserStats = {};

//UserStats[32983] = {0:500,1:500,2:500,PlayerID:32983,Population:0,MaxPopulation:0};

//Tiles["1:1"] = {Type:TileType.KEEP,OwnerId:32983,Health:100};
///Tiles["1:2"] = {Type:TileType.PATH,OwnerId:32983};
//Tiles["1:3"] = {Type:TileType.HOUSE,OwnerId:32983};
//Tiles["2:2"] = {Type:TileType.FARM,OwnerId:32983};

//Units["Dev:1"] = {Type:UnitType.VILLAGER,ID:"Dev:1",OwnerId:32983,Posx:1,Posy:3,Health:100,Fatigue:0,Home:"1:3",Work:"2:2",Target:"2:2",HeldResource:undefined};

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

}

function addResource(id, resource){
    var stats = UserStats[id];

    if (!stats){
        console.warn("Attempted to alter unknown users stats:", id, resource);
        return;
    }

    stats[resource.Type] += resource.Amount;
}

function useResource(id, resource){
    var stats = UserStats[id];

    if (!stats){
        console.warn("Attempted to alter unknown users stats:", id, resource);
        return;
    }

    stats[resource.Type] -= resource.Amount;
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
    return obj1.f - obj2.f;
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

//A* implementation
function findPath(start, target) {
    var openSet = new SortedSet([], openSetEquals, fCompare);
    var closedSet = new Set();
    var cameFrom = {};
    var gScore = {};
    var iterations = 0;

    openSet.push({p:start,f:costHeuristic(start, target)});
    gScore[start] = 0;

    while (iterations++ < 3000) {
        var current = openSet.min();

        if (!openSet.remove(current)) return false;
        if (current.p == target) return reconstructPath(start, target, cameFrom);

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

    while (current = searchQueue.shift()){
        var neighbours = getNeighbours(current);
        var neighbour, type;

        for (var i in neighbours) {
            neighbour = neighbours[i];
            type = safeType(neighbour);

            if (type == TileType.STORAGE || type == TileType.KEEP)
                return neighbour;
            else if (type == TileType.PATH)
                searchQueue.push(neighbour);
            
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

async function process() {
    var t1 = performance.now();
    var processed = 0;

    await fetchRedisData();

    let unitpipe = redis.pipeline();

    for (var id in Units){
        processed++;
        var unit = Units[id];
        var [state, pos, target] = establishUnitState(unit)

        switch(state){
            case UnitState.MOVING:
                var path = findPath(pos, target);
                if (!path) {console.warn("Unit could not find a path!");return;}
                [unit.Posx, unit.Posy] = toPosition(path[0]);
                unitpipe.hset('units', id, JSON.stringify(unit));
                break;

            case UnitState.WORKING:
                var produce = getTileOutput(pos);
                addProduceToUnit(unit, produce)
                if (unit.Fatigue++ >= MAX_FATIGUE)
                    unit.Target = findClosestStorage(pos);
                
                unitpipe.hset('units', id, JSON.stringify(unit));
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

                unitpipe.hset('units', id, JSON.stringify(unit));
                break;
        }
    }

    var t2 = performance.now();
    console.log("Processed", processed, "units in", Math.round((t2 - t1)*100)/100, "ms");

    unitpipe.exec((err, results) => {
        if (err) console.warn("Error executing redis unit pipeline! ", err);
    });

    var t3 = performance.now();
    console.log("Redis pipeline executed in", Math.round((t3 - t2)*100)/100, "ms");
    console.log("Total round time took", Math.round((t3 - t1)*100)/100, "ms");
}

console.log("Pioneers processing backend starting....");
fetchRedisData();
setInterval(process, 2000);
