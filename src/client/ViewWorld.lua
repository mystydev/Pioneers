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
local UPDATE_THROTTLE = 300

local function isTile(inst)
    if not inst then return end
    
    if inst:IsA("MeshPart") then
        return true
    end
end

local updateCount = 0
function ViewWorld.displayWorld(world)
    CurrentWorld = world
    
    local tiles = world.Tiles
    local units = world.Units

    ViewTile.init(tiles)
    ViewUnit.init(world)

    delay(0, function()
        while true do
            local pos, posx, posy

            pos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
            posx, posy = pos.x, pos.y

            local area = Util.circularCollection(tiles, posx, posy, 0, 15)

            for _, tile in pairs(area) do
                ViewTile.displayTile(tile)
                updateCount = updateCount + 1
                if (updateCount > UPDATE_THROTTLE) then 
                    updateCount = 0 
                    RunService.Stepped:Wait() 
                end
            end
            RunService.Stepped:Wait()
        end
    end)

    local edgeSize = 6
    delay(0, function()
        while true do
            local pos, posx, posy

            pos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
            posx, posy = pos.x, pos.y

            local area = Util.circularCollection(tiles, posx, posy, 15, ClientUtil.getCurrentViewDistance()-edgeSize-1)

            for _, tile in pairs(area) do
                ViewTile.displayTile(tile, "SKIP")
                updateCount = updateCount + 1
                if (updateCount > UPDATE_THROTTLE) then 
                    updateCount = 0 
                    RunService.Stepped:Wait() 
                end
            end

            for edge = edgeSize, 0, -1 do
                local area = Util.circularCollection(tiles, posx, posy, ClientUtil.getCurrentViewDistance()-edge-1, ClientUtil.getCurrentViewDistance()-edge)

                for _, tile in pairs(area) do
                    ViewTile.displayTile(tile, edge/edgeSize)
                    updateCount = updateCount + 1
                    if (updateCount > UPDATE_THROTTLE) then 
                        updateCount = 0 
                        RunService.Stepped:Wait() 
                    end
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

function ViewWorld.convertInstanceToObject(inst)
    return ViewWorld.convertInstanceToTile(inst) or ViewWorld.convertInstanceToUnit(inst)
end

function ViewWorld.convertObjectToInst(object)
    return ViewTile.getInstFromTile(object) or ViewUnit.getInstFromUnit(object)
end

return ViewWorld