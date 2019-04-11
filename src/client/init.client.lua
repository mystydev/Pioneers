local Client = script
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile           = require(Common.Tile)
local Unit           = require(Common.Unit)
local World          = require(Common.World)
local Util           = require(Common.Util)
local UserStats      = require(Common.UserStats)
local Resource       = require(Common.Resource)
local ViewTile       = require(Client.ViewTile)
local ViewWorld      = require(Client.ViewWorld)
local ViewStats      = require(Client.ViewStats)
local ViewSelection  = require(Client.ViewSelection)
local TilePlacement  = require(Client.TilePlacement)
local UnitController = require(Client.UnitController)
local Replication    = require(Client.Replication)
local ClientUtil     = require(Client.ClientUtil)


print("Pioneers client waiting for server to be ready")
repeat wait() until Replication.ready()

print("Pioneers client starting...")

ClientUtil.init()

local world = Replication.getWorldState()
ViewWorld.displayWorld(world)

--wait(2)
local stats = Replication.getUserStats()

ViewStats.createDisplay(stats)
ViewSelection.createDisplay()

workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(0, 30, 0))