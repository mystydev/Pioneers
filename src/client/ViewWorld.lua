local ViewWorld = {}
local Client    = script.Parent
local Common    = game.ReplicatedStorage.Pioneers.Common

local ViewTile    = require(Client.ViewTile)
local ViewUnit    = require(Client.ViewUnit)
local ClientUtil  = require(Client.ClientUtil)
local Replication = require(Client.Replication)
local World       = require(Common.World)
local Util        = require(Common.Util)

local RunService = game:GetService("RunService")

local CurrentWorld

function ViewWorld.displayWorld(world)
    CurrentWorld = world
    
    local tiles = world.Tiles
    local units = world.Units

    ViewTile.init(tiles)
    ViewUnit.init(world)

    Replication.keepViewAreaLoaded()

    for id, unit in pairs(units) do 
        ViewUnit.displayUnit(unit)
    end
end

function ViewWorld.convertInstanceToTile(inst)
    return ViewTile.getTileFromInst(inst)
end

function ViewWorld.convertInstanceToUnit(inst)
    return ViewUnit.getUnitFromInst(inst)
end

function ViewWorld.convertInstanceToObject(inst)
    return ViewWorld.convertInstanceToTile(inst) 
            or ViewWorld.convertInstanceToUnit(inst)
end

function ViewWorld.convertObjectToInst(object)
    if type(object) == "string" then --reference tile by position id, doesn't make sense to do so with units
        object = CurrentWorld.Tiles[object]
    end

    return ViewTile.getInstFromTile(object) 
            or ViewUnit.getInstFromUnit(object)
end

return ViewWorld