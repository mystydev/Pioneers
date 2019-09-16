local ActionHandler = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Util        = require(Common.Util)
local Unit        = require(Common.Unit)
local ViewTile    = require(Client.ViewTile)
local Replication = require(Client.Replication)
local Players = game:GetService("Players")

local currentWorld
local unitChangeHook = function() end

function ActionHandler.init(world)
    currentWorld = world
end

function ActionHandler.provideUnitChangeHook(hook)
    unitChangeHook = hook
end

function ActionHandler.attemptBuild(tile, type)
    local oldType = tile.Type
    local oldId = tile.OwnerId
    tile.Type = type
    tile.OwnerId = Players.LocalPlayer.UserId
    ViewTile.updateDisplay(tile)
    tile.lastChange = tick()

    for _, n in pairs(Util.getNeighbours(currentWorld.Tiles, tile.Position)) do
        ViewTile.updateDisplay(n)
    end

    Replication.requestTilePlacement(tile, type)

    delay(5, function()
        local liveTile = Replication.requestTile(tile.Position)
        Replication.handleTileUpdate(liveTile)
        
        for _, n in pairs(Util.getNeighbours(currentWorld.Tiles, tile.Position)) do
            ViewTile.updateDisplay(n)
        end
    end)
end

function ActionHandler.assignWork(unit, tile)
    Replication.requestUnitWork(unit, tile)

    --Simulate unassigned work
    if tile == nil then

        if not Unit.isMilitary(unit) then
            unit.Type = Unit.VILLAGER
        end

        unit.Work = nil
        unitChangeHook()
    end
end

function ActionHandler.chatted(message)
    Replication.sendChat(message)
end

function ActionHandler.sendFeedback(react, text)
    Replication.sendFeedback(react, text)
end

return ActionHandler