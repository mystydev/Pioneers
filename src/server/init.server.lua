local Server = script
local Common = game.ReplicatedStorage.Pioneers.Common

print("Pioneers loading modules...") 

local Replication = require(Server.Replication)
local Sync        = require(Server.Sync)
local World       = require(Common.World)

local Players = game:GetService("Players")

print("Pioneers server starting...")

local world = World.new()

Sync.begin(world)

print("Server synced and ready!")

Replication.assignWorld(world)
