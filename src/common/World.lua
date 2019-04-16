local World  = {}
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile = require(Common.Tile)

local format = string.format

function World.new(Tiles, Units)
    local new = {}

    new.Tiles = Tiles or {}
    new.Units = Units or {}

    return new
end

function World.setTile(tiles, tile, x, y)
    tiles[format("%d:%d", x, y)] = tile
end

function World.getTile(tiles, x, y)
    local tile = tiles[format("%d:%d", x, y)]

    if not tile then
        tile = {Type = Tile.GRASS, Position = Vector2.new(x, y)}
        World.setTile(tiles, tile, x, y)
    end

    return tile
end

return World