local ViewWorld = {}

local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ViewTile = require(Client.ViewTile)
local ViewUnit = require(Client.ViewUnit)
local World = require(Common.World)
local Util = require(Common.Util)

local CurrentWorld

function ViewWorld.displayWorld(world)

    CurrentWorld = world
    
    local tiles = world.Tiles
    local units = world.Units

    for x = 1, World.SIZE do 
        for y = 1, World.SIZE do
            local tile = tiles[x][y]

            if tile then ViewTile.displayTile(tile) end
        end
    end

    for id, unit in pairs(units) do 
        ViewUnit.displayUnit(unit)
    end
end

function ViewWorld.convertInstanceToObject(inst)

    local pos = Util.worldCoordToAxialCoord(inst.Position)

    return CurrentWorld.Tiles[pos.x][pos.y]
end


return ViewWorld