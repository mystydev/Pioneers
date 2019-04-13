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
local getTile = World.getTile

local function isTile(inst)
    if inst.Name == "Hexagon" then
        return true
    end
end

function ViewWorld.displayWorld(world)
    CurrentWorld = world
    
    local tiles = world.Tiles
    local units = world.Units

    delay(0, function()

        --wait(0.5)

        pos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
        posx, posy = pos.x, pos.y

        ViewTile.displayTile(getTile(tiles, posx, posy))

        for radius = 0, 25 do
            for i = 0, radius-1 do
                ViewTile.displayTile(getTile(tiles, posx + i, posy + radius))
                ViewTile.displayTile(getTile(tiles, posx + radius, posy + radius - i))
                ViewTile.displayTile(getTile(tiles, posx + radius - i, posy - i))
                ViewTile.displayTile(getTile(tiles, posx - i, posy - radius))
                ViewTile.displayTile(getTile(tiles, posx - radius, posy - radius + i))
                ViewTile.displayTile(getTile(tiles, posx - radius + i, posy + i))
                --RunService.Stepped:Wait()
            end
            --RunService.Stepped:Wait()
        end

        while true do
            local pos, posx, posy

            pos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
            posx, posy = pos.x, pos.y
            for radius = 0, 25 do
                for i = 0, radius-1 do
                    ViewTile.displayTile(getTile(tiles, posx + i, posy + radius))
                    ViewTile.displayTile(getTile(tiles, posx + radius, posy + radius - i))
                    ViewTile.displayTile(getTile(tiles, posx + radius - i, posy - i))
                    ViewTile.displayTile(getTile(tiles, posx - i, posy - radius))
                    ViewTile.displayTile(getTile(tiles, posx - radius, posy - radius + i))
                    ViewTile.displayTile(getTile(tiles, posx - radius + i, posy + i))
                end
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

return ViewWorld