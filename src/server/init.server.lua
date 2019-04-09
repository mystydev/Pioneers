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
local format = string.format

local tiles = {}
local units = {}

local world = World.new(tiles, units)

Replication.assignWorld(world)
ProcessRound.assignWorld(world)

Players.PlayerAdded:Connect(function(player)
    StatsController.addNewPlayer(player)
end)

while wait(0.2) do
    ProcessRound.process()
end