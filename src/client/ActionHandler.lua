local ActionHandler = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Util        = require(Common.Util)
local Unit        = require(Common.Unit)
local Tile        = require(Common.Tile)
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

local function tempChangeTileType(tile, type, newId)
    --Save current tile info to restore if needed later
    local oldType = tile.Type
    local oldId = tile.OwnerId
    local version = tile.CyclicVersion

    --Assign new info
    tile.Type = type
    tile.OwnerId = newId

    --Update display
    ViewTile.updateDisplay(tile)
    tile.lastChange = tick()

    --Update neighbouring tiles
    for _, n in pairs(Util.getNeighbours(currentWorld.Tiles, tile.Position)) do
        ViewTile.updateDisplay(n)
    end

    --Wait to see if request failed and tile needs to be restored
    delay(5, function()

        --Version didn't change so no update happened
        if version == tile.CyclicVersion then
            tile.Type = oldType
            tile.OwnerId = oldId

            ViewTile.updateDisplay(tile)

            for _, n in pairs(Util.getNeighbours(currentWorld.Tiles, tile.Position)) do
                ViewTile.updateDisplay(n)
            end
        end
    end)
end

function ActionHandler.attemptBuild(tile, type)
    --Update tile then send request to place the tile
    tempChangeTileType(tile, type, Players.LocalPlayer.UserId)
    Replication.requestTilePlacement(tile, type, Players.LocalPlayer.UserId)
end

function ActionHandler.attemptDelete(tile)
    --Update tile then send request to delete the tile
    tempChangeTileType(tile, Tile.GRASS, nil)
    Replication.requestTileDelete(tile)
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