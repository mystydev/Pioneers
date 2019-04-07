
local World = {}
local Vector2 = Vector2

local Common = game.ReplicatedStorage.Pioneers.Common
local Tile = require(Common.Tile)

World.SIZE = 20 --How big on each axis the world is
                --For example 10 = 0->10 inclusive
                --This uses the axial coordinate system

local function hasNeighour(tiles, tile, type)
    local posx, posy = tile.Position.x, tile.Position.y

    return (tiles[posx  ][posy+1].Type == type
            or tiles[posx  ][posy+1].Type == type
            or tiles[posx+1][posy+1].Type == type
            or tiles[posx+1][posy  ].Type == type
            or tiles[posx  ][posy-1].Type == type
            or tiles[posx-1][posy-1].Type == type
            or tiles[posx-1][posy  ].Type == type)
end

local function nearHostile(tiles, tile, ID)
    local posx, posy = tile.Position.x, tile.Position.y

    for radius = 1, 4 do
        local id

        for i = 0, radius-1 do
            id = tiles[posx + i][posy + radius].OwnerID
            if id and id ~= ID then return true end

            id = tiles[posx + radius][posy + radius - i].OwnerID
            if id and id ~= ID then return true end

            id = tiles[posx + radius - i][posy - i].OwnerID
            if id and id ~= ID then return true end

            id = tiles[posx - i][posy - radius].OwnerID
            if id and id ~= ID then return true end

            id = tiles[posx - radius][posy - radius + i].OwnerID
            if id and id ~= ID then return true end

            id = tiles[posx - radius + i][posy + i].OwnerID
            if id and id ~= ID then return true end
        end
    end
end

function World.new(Tiles, Units)
    local new = {}

    new.Tiles = Tiles
    new.Units = Units

    return new
end

function World.tileCanBePlaced(world, tile, type, ID)
    local tiles = world.Tiles
    local pos = tile.Position
    local currentTile = tiles[pos.x][pos.y]

    if nearHostile(tiles, currentTile, ID) then
        return false end

    if currentTile.Type == Tile.GRASS then
        if type == Tile.KEEP then
            return true
        elseif type == Tile.PATH and hasNeighour(tiles, tile, Tile.KEEP) then
            return true
        elseif hasNeighour(tiles, tile, Tile.PATH) then
            return true
        end
    end
end

function World.computeHash(world)

    local tileHashValue = 0

    for x = 0, World.SIZE do
        for y = 0, World.SIZE do
            tileHashValue = ((tileHashValue + 1) * (world.Tiles[x][y].Type + 1) * x * y) % 1677216
        end
    end

    local unitHashValue = 0

    for id, unit in pairs(world.Units) do 
        unitHashValue = ((unitHashValue + 1) * (unit.Type + 1 * unit.Position.x * unit.Position.y) * unit.OwnerID) % 1677216
    end

    local hash = string.format("%08x%08x", tileHashValue, unitHashValue)

    return hash
end

return World