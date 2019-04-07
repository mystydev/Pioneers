local Server = script
local Common = game.ReplicatedStorage.Pioneers.Common

local ProcessRound    = require(Server.ProcessRound)
local Replication     = require(Server.Replication)
local StatsController = require(Server.StatsController)
local World           = require(Common.World)
local Tile            = require(Common.Tile)
local Unit            = require(Common.Unit)
local UserStats       = require(Common.UserStats)

local Players = game:GetService("Players")

local tiles = {}
local units = {}

for x = 1, World.SIZE do
    tiles[x] = {}

    for y = 1, World.SIZE do
        tiles[x][y] = Tile.new(Tile.GRASS, nil, Vector2.new(x, y), nil)
    end
end

local world = World.new(tiles, units)

Replication.assignWorld(world)
ProcessRound.assignWorld(world)

Players.PlayerAdded:Connect(function(player)
    StatsController.addNewPlayer(player)
end)

while wait(2) do
    ProcessRound.process()
end