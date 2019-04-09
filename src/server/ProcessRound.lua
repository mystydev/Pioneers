local ProcessRound = {}
local Server       = script.Parent
local Common       = game.ReplicatedStorage.Pioneers.Common

local Pathfinding     = require(Common.Pathfinding)
local Resource        = require(Common.Resource)
local Tile            = require(Common.Tile)
local World           = require(Common.World)
local UnitController  = require(Server.UnitController)
local StatsController = require(Server.StatsController)

local MAX_FATIGUE = 10

local UnitState = {}
UnitState.IDLE = 0
UnitState.DEAD = 1
UnitState.MOVING = 2
UnitState.WORKING = 3
UnitState.RESTING = 4
UnitState.STORING = 5

local StateLocalisation = {}
StateLocalisation[UnitState.IDLE] = "Idle"
StateLocalisation[UnitState.DEAD] = "Dead"
StateLocalisation[UnitState.MOVING] = "Moving"
StateLocalisation[UnitState.WORKING] = "Working"
StateLocalisation[UnitState.RESTING] = "Resting"
StateLocalisation[UnitState.STORING] = "Storing"

local currentWorld 

local function establishUnitState(unit)
    local onTile = World.getTile(currentWorld.Tiles, unit.Position.x, unit.Position.y)
    local hasHome = unit.Home
    local hasWork = unit.Work
    local hasTarget = unit.Target
    local hasResource = unit.HeldResource
    local atHome = onTile == hasHome
    local atWork = onTile == hasWork
    local atTarget = onTile == hasTarget
    local atStorage = (onTile.Type == Tile.STORAGE) or (onTile.Type == Tile.KEEP)

    if unit.Health == 0 then
        return UnitState.DEAD, onTile
    elseif hasTarget and not atTarget then
        return UnitState.MOVING, onTile, hasTarget
    elseif unit.Fatigue < MAX_FATIGUE and atWork then
        return UnitState.WORKING, onTile,  hasWork
    elseif hasResource then
        return UnitState.STORING, onTile
    elseif unit.Fatigue > 0 and atHome then
        return UnitState.RESTING, onTile
    else
        return UnitState.IDLE, onTile
    end

end

local function getNumSharedNeighbours(tile)
    local neighbours = Pathfinding.getNeighbours(tile)

    local count = 0

    for _, n in pairs(neighbours) do
        if n.Type == tile.Type then
            count = count + 1
        end
    end

    return count
end

local function getTileOutput(tile)
    if tile.Type == Tile.FARM then
        return Resource.new(Resource.FOOD, 1 + getNumSharedNeighbours(tile))
    elseif tile.Type == Tile.FORESTRY then
        return Resource.new(Resource.WOOD, 1 + getNumSharedNeighbours(tile))
    elseif tile.Type == Tile.MINE then
        return Resource.new(Resource.STONE, 1 + getNumSharedNeighbours(tile))
    end
end

local function processUnit(unit) 
    local state, onTile, targetTile = establishUnitState(unit)

    if state == UnitState.MOVING then
        local path = Pathfinding.findPath(onTile, targetTile)
        
        if not path then
            print("Unit could not find a path!")
            return end

        UnitController.assignPosition(unit, path[1].Position)

    elseif state == UnitState.WORKING then
        local produce = getTileOutput(onTile)
        UnitController.addResource(unit, produce)

        --print("Unit has", unit.HeldResource.Amount, "of",  Resource.Localisation[unit.HeldResource.Type])

        unit.Fatigue = unit.Fatigue + 1

        if unit.Fatigue >= MAX_FATIGUE then
            unit.Target = Pathfinding.findClosestStorage(onTile)
        end
    
    elseif state == UnitState.RESTING then

        if StatsController.useResource(unit.OwnerID, Resource.new(Resource.FOOD, 5)) then

            unit.Fatigue = unit.Fatigue - 5
            if unit.Fatigue <= 0 then
                unit.Fatigue = 0
                unit.Target = unit.Work
            end

        else
            print("Not enough food!")
        end

    elseif state == UnitState.STORING then 
        if onTile.Type == Tile.STORAGE or onTile.Type == Tile.KEEP then
            --print("Stored", unit.HeldResource.Amount, "of", Resource.Localisation[unit.HeldResource.Type])
            StatsController.addResource(unit.OwnerID, unit.HeldResource)
            unit.HeldResource = nil

            if unit.Fatigue > 0 then
                unit.Target = unit.Home
            end

        else
            unit.Target = Pathfinding.findClosestStorage(onTile)
        end
    end

    --print("Unit:", unit.ID, "is", StateLocalisation[state])
end 

function ProcessRound.process()
    for id, unit in pairs(currentWorld.Units) do
        processUnit(unit)
    end
end

function ProcessRound.assignWorld(w)
    currentWorld = w
    Pathfinding.assignWorld(w)
end

return ProcessRound