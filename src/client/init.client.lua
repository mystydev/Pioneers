local Client = script
local Common = game.ReplicatedStorage.Pioneers.Common

local ViewWorld       = require(Client.ViewWorld)
local ViewStats       = require(Client.ViewStats)
local Replication     = require(Client.Replication)
local ObjectSelection = require(Client.ObjectSelection)
local World           = require(Common.World)

print("Pioneers client waiting for server to be ready")

repeat wait() until Replication.ready()

print("Pioneers client starting...")

local world = World.new()
Replication.init(world)
ViewWorld.displayWorld(world)

local stats = Replication.getUserStats()

ObjectSelection.init(world, stats)
ViewStats.init(stats)

workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 30, 0))