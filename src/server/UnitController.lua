local UnitController = {}
local Server         = script.Parent
local Common         = game.ReplicatedStorage.Pioneers.Common

local Replication     = require(Server.Replication)
local StatsController = require(Server.StatsController)
local Unit            = require(Common.Unit)
local Tile            = require(Common.Tile)
local Pathfinding     = require(Common.Pathfinding)
local Resource        = require(Common.Resource)

local unitCount = 5
local currentWorld

function UnitController.assignPosition(unit, position)
    unit.Position = position
    Replication.pushUnitChange(unit)
end

function UnitController.addResource(unit, resource)
    local heldResource = unit.HeldResource

    if heldResource then
        if heldResource.Type == resource.Type then
            heldResource.Amount = heldResource.Amount + resource.Amount
        else
            print("Tried to add resource to unit when unit has a different resource!")
        end
    else
        unit.HeldResource = resource
    end

    Replication.pushUnitChange(unit)
end

function UnitController.spawnUnit(ID, house)
    
    local storage, dist = Pathfinding.findClosestStorage(house)
    
    if not dist or dist > 10 then
        return end

    local unit = Unit.new(Unit.VILLAGER, tostring(ID)..":"..unitCount, ID, house.Position, 100, 0, nil, nil, nil, nil)
    
    if UnitController.setHome(unit, house) then
        if StatsController.useResource(unit.OwnerID, Resource.new(Resource.FOOD, 100)) then

            currentWorld.Units[unit.ID] = unit
            unitCount = unitCount + 1
            Replication.pushUnitChange(unit)

            return true
        else
            print("Not enough food to spawn a new unit")
            UnitController.setHome(unit, nil) --TODO: memory leak?
            return false
        end
    else
        return false
    end
end

function UnitController.setHome(unit, house)

    if unit.Home then
        if unit.Home.Member1 == unit then
            unit.Home.Member1 = nil
        elseif unit.Home.Member2 == unit then
            unit.Home.Member2 = nil
        else
            warn("Unit was assigned to a home but that home did not contain it as a member!")
        end
    end


    if not house or house.Type ~= Tile.HOUSE then
        unit.Home = nil
        return end


    if not house.Member1 then
        house.Member1 = unit.ID
    elseif not house.Member2 then
        house.Member2 = unit.ID
    else
        return false
    end

    unit.Home = house

    return true
end

function UnitController.setWork(unit, work)

    if work.Type ~= Tile.FARM
        and work.Type ~= Tile.FORESTRY
        and work.Type ~= Tile.MINE then
        return end

    if unit.Work then
        if unit.Work.Member1 == unit.ID then
            unit.Work.Member1 = nil
        else
            warn("Unit was assigned to a work but that work did not contain it as a member!")
        end
    end

    if not work.Member1 then
        work.Member1 = unit.ID
    else
        return false
    end

    unit.Work = work
    UnitController.setTarget(unit, work)

    return true
end

function UnitController.setTarget(unit, target)

    if target.Type == Tile.GRASS then
        return end

    unit.Target = target

    return true
end

function UnitController.assignWorld(world)
    currentWorld = world
end

return UnitController