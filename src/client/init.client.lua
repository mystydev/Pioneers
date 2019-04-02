local Client = script
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile     = require(Common.Tile)
local World    = require(Common.World)
local ViewTile = require(Client.ViewTile)
local ViewWorld = require(Client.ViewWorld)
local ViewResources = require(Client.ViewResources)

print("Pioneers client starting...")

local tiles = {}

for x = 0, World.SIZE do
    tiles[x] = {}

    for y = 0, World.SIZE do

        tiles[x][y] = Tile.new(math.random(0, 10), 0, Vector2.new(x, y), 0)
    end
end


local world = World.new(tiles, {})
ViewWorld.displayWorld(world)

ViewResources.createDisplay()