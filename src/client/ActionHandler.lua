local ActionHandler = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Util        = require(Common.Util)
local ViewTile    = require(Client.ViewTile)
local Replication = require(Client.Replication)
local Players = game:GetService("Players")

local currentWorld

function ActionHandler.init(world)
    currentWorld = world
end

function ActionHandler.attemptBuild(tile, type)
    tile.Type = type
    tile.OwnerId = Players.LocalPlayer.UserId
    tile.lastChange = tick()

    ViewTile.updateDisplay(tile)

    for _, n in pairs(Util.getNeighbours(currentWorld.Tiles, tile.Position)) do
        ViewTile.updateDisplay(n)
    end

    spawn(function()
        local status = Replication.requestTilePlacement(tile, type)
    end)
end



return ActionHandler