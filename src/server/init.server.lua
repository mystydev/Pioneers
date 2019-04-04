local Server = script
local Common = game.ReplicatedStorage.Pioneers.Common
local World    = require(Common.World)
local Tile    = require(Common.Tile)
local Unit    = require(Common.Unit)
local UserStats = require(Common.UserStats)
local ProcessRound = require(Server.ProcessRound)
local Replication = require(Server.Replication)
local StatsController = require(Server.StatsController)

local tiles = {}
local units = {}

for x = 1, World.SIZE do
    tiles[x] = {}

    for y = 1, World.SIZE do
        tiles[x][y] = Tile.new(Tile.GRASS, nil, Vector2.new(x, y), nil)
    end
end

local home = tiles[2][2]
local work = tiles[2][5]
local work2 = tiles[5][2]

home.Type = Tile.HOUSE
work.Type = Tile.FARM
work2.Type = Tile.FORESTRY
tiles[2][3].Type = Tile.PATH
tiles[2][4].Type = Tile.PATH
tiles[3][3].Type = Tile.PATH
tiles[4][3].Type = Tile.PATH
tiles[5][3].Type = Tile.PATH
tiles[5][4].Type = Tile.PATH
tiles[3][4].Type = Tile.STORAGE

units["DEV:0"] = Unit.new(Unit.VILLAGER, "DEV:0", 0, Vector2.new(2, 2), 100, 0, home, work, work, nil)
units["DEV:1"] = Unit.new(Unit.VILLAGER, "DEV:1", 0, Vector2.new(2, 2), 100, 0, home, work2, work2, nil)

local world = World.new(tiles, units)

Replication.assignWorld(world)

ProcessRound.assignWorld(world)

local stats = UserStats.new(23, 10, 16, 0, 0, 0)
Replication.tempAssignStats(stats)
StatsController.tempAddStats(stats)
while wait(1) do
    ProcessRound.process()
end