local ViewWorld = {}
local Client    = script.Parent
local Common    = game.ReplicatedStorage.Pioneers.Common

local ViewTile   = require(Client.ViewTile)
local ViewUnit   = require(Client.ViewUnit)
local ClientUtil = require(Client.ClientUtil)
local World      = require(Common.World)
local Util       = require(Common.Util)

local RunService = game:GetService("RunService")

local CurrentWorld

local function isTile(inst)
    if not inst then return end
    
    if inst.Name == "Hexagon" then --TODO: this
        return true
    end
end

function ViewWorld.displayWorld(world)
    CurrentWorld = world
    
    local tiles = world.Tiles
    local units = world.Units

    delay(0, function()
        while true do
            local pos, posx, posy

            pos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
            posx, posy = pos.x, pos.y

            local area = Util.circularCollection(tiles, posx, posy, 0, 25)

            for _, tile in pairs(area) do
                ViewTile.displayTile(tile)
            end

            RunService.Stepped:Wait()
        end
    end)

    for id, unit in pairs(units) do 
        ViewUnit.displayUnit(unit)
    end
end

function ViewWorld.convertInstanceToTile(inst)

    if isTile(inst) then

        local pos = Util.worldCoordToAxialCoord(inst.Position)
        return World.getTile(CurrentWorld.Tiles, pos.x, pos.y)

    end
end

function ViewWorld.convertInstanceToUnit(inst)
    return ViewUnit.getUnitFromInst(inst)
end

function ViewWorld.convertInstanceToObject(inst)
    return ViewWorld.convertInstanceToTile(inst) or ViewWorld.convertInstanceToUnit(inst)
end

function ViewWorld.convertObjectToInst(object)
    return ViewTile.getTileFromInst(inst) or ViewUnit.getInstFromUnit(object)
end

return ViewWorld