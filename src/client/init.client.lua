local Client = script

local ViewWorld       = require(Client.ViewWorld)
local ViewStats       = require(Client.ViewStats)
local Replication     = require(Client.Replication)
local ObjectSelection = require(Client.ObjectSelection)

print("Pioneers client waiting for server to be ready")

repeat wait() until Replication.ready()

print("Pioneers client starting...")

local world = Replication.getWorldState()
ObjectSelection.init(world)
ViewWorld.displayWorld(world)

local stats = Replication.getUserStats()

ViewStats.createDisplay(stats)

workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 30, 0))