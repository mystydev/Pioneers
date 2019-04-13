local Server = script
local Common = game.ReplicatedStorage.Pioneers.Common

print("Pioneers loading modules...") 

local ProcessRound    = require(Server.ProcessRound)
local Replication     = require(Server.Replication)
local StatsController = require(Server.StatsController)
local Sync            = require(Server.Sync)
local World           = require(Common.World)
local Tile            = require(Common.Tile)
local Unit            = require(Common.Unit)
local UserStats       = require(Common.UserStats)

local Players = game:GetService("Players")
local format = string.format

local tiles = {}
local units = {}

print("Pioneers server starting...")

local world = World.new(tiles, units)

Sync.begin(world)

print("Still starting...")

Replication.assignWorld(world)
ProcessRound.assignWorld(world)


while wait(0.2) do
    --ProcessRound.process()
end