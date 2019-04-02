local Client = script
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile     = require(Common.Tile)
local ViewTile = require(Client.ViewTile)

print("Pioneers client starting...")



for x = -10, 10 do
    for y = -10, 10 do

        ViewTile.displayTile(
            Tile.new(Tile.GRASS, 0, Vector2.new(x, y), 0)
        )

    end
end