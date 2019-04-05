local Client = script
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile     = require(Common.Tile)
local Unit     = require(Common.Unit)
local World    = require(Common.World)
local Util     = require(Common.Util)
local UserStats = require(Common.UserStats)
local Resource = require(Common.Resource)
local ViewTile = require(Client.ViewTile)
local ViewWorld = require(Client.ViewWorld)
local ViewStats = require(Client.ViewStats)
local TilePlacement = require(Client.TilePlacement)
local UnitController = require(Client.UnitController)
local Replication = require(Client.Replication)

print("Pioneers client starting...")

local world = Replication.getWorldState()
ViewWorld.displayWorld(world)

local stats = Replication.getUserStats()

ViewStats.createDisplay(stats)

workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(1000, 50, 1000))