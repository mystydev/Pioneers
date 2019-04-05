local ViewWorld = {}

local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ViewTile = require(Client.ViewTile)
local ViewUnit = require(Client.ViewUnit)
local World = require(Common.World)
local Util = require(Common.Util)

local CurrentWorld

local function isTile(inst)
    if inst.Name == "Hexagon" then
        return true
    end
end

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

function ViewWorld.convertInstanceToTile(inst)

    if isTile(inst) then

        local pos = Util.worldCoordToAxialCoord(inst.Position)
        return CurrentWorld.Tiles[pos.x][pos.y]

    end
end

function ViewWorld.convertInstanceToUnit(inst)
    return ViewUnit.getUnitFromInst(inst)
end

return ViewWorld