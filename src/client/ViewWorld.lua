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

    spawn(function()
        while true do

            local pos  = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
            local area = Util.circularCollection(tiles, pos.x, pos.y, 0, ClientUtil.getCurrentViewDistance())

            for _, tile in pairs(area) do
                ViewTile.displayTile(tile, "SKIP")
                RunService.Stepped:Wait() 
            end
        end
    end)

    
    spawn(function()

        local edgeSize = 6

        while true do
            local pos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
            local viewDistance = ClientUtil.getCurrentViewDistance()+edgeSize

            for edge = edgeSize, 1, -1 do
                local area = Util.circularCollection(tiles, pos.x, pos.y, viewDistance-edge-1, viewDistance-edge)

                for _, tile in pairs(area) do
                    ViewTile.displayTile(tile, edge/edgeSize)

                    updateCount = (updateCount + 1)%UPDATE_THROTTLE
                    if (updateCount == 0) then 
                        RunService.Stepped:Wait() 
                    end
                end
            end
        end
    end)

    for id, unit in pairs(units) do 
        ViewUnit.displayUnit(unit)
    end
end

function ViewWorld.convertInstanceToTile(inst)

    if not isTile(inst) then
        return end

    local pos = Util.worldCoordToAxialCoord(inst.Position)
    return World.getTile(CurrentWorld.Tiles, pos.x, pos.y)
end

function ViewWorld.convertInstanceToUnit(inst)
    return ViewUnit.getUnitFromInst(inst)
end

function ViewWorld.convertInstanceToObject(inst)
    return ViewWorld.convertInstanceToTile(inst) 
            or ViewWorld.convertInstanceToUnit(inst)
end

function ViewWorld.convertObjectToInst(object)
    return ViewTile.getInstFromTile(object) 
            or ViewUnit.getInstFromUnit(object)
end

return ViewWorld