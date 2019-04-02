local Client = script
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile     = require(Common.Tile)
local Unit     = require(Common.Unit)
local World    = require(Common.World)
local ViewTile = require(Client.ViewTile)
local ViewWorld = require(Client.ViewWorld)
local ViewResources = require(Client.ViewResources)

print("Pioneers client starting...")

local tiles = {}
local units = {}

for x = 0, World.SIZE do
    tiles[x] = {}
    units[x] = {}

    for y = 0, World.SIZE do

        tiles[x][y] = Tile.new(Tile.GRASS, 0, Vector2.new(x, y), 0)
    end
end

units[1][1] = Unit.new(Unit.VILLAGER, 0, Vector2.new(1, 1), 100, 0, nil, nil, nil, nil)


local world = World.new(tiles, units)
ViewWorld.displayWorld(world)

ViewResources.createDisplay()