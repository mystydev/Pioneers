
local World  = {}
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile = require(Common.Tile)

local format = string.format
local vec3 = Vector3.new

local function setTile(tiles, tile, x, y)
    tiles[format("%d:%d", x, y)] = tile
end

local function getTile(tiles, x, y)
    local tile = tiles[format("%d:%d", x, y)]

    if not tile then  
        setTile(tiles, Tile.new(Tile.GRASS, nil, vec3(x, y, 0), nil), x, y)
    end

    return tiles[format("%d:%d", x, y)]
end

local function hasNeighour(tiles, tile, type)
    local posx, posy = tile.Position.x, tile.Position.y

    return (getTile(tiles, posx, posy+1).Type == type
            or getTile(tiles, posx, posy+1).Type == type
            or getTile(tiles, posx+1, posy+1).Type == type
            or getTile(tiles, posx+1, posy  ).Type == type
            or getTile(tiles, posx  , posy-1).Type == type
            or getTile(tiles, posx-1, posy-1).Type == type
            or getTile(tiles, posx-1, posy  ).Type == type)
end

local function nearHostile(tiles, tile, ID)
    local posx, posy = tile.Position.x, tile.Position.y

    for radius = 1, 4 do
        local id

        for i = 0, radius-1 do
            id = getTile(tiles, posx + i, posy + radius).OwnerID
            if id and id ~= ID then return true end

            id = getTile(tiles, posx + radius, posy + radius - i).OwnerID
            if id and id ~= ID then return true end

            id = getTile(tiles, posx + radius - i, posy - i).OwnerID
            if id and id ~= ID then return true end

            id = getTile(tiles, posx - i, posy - radius).OwnerID
            if id and id ~= ID then return true end

            id = getTile(tiles, posx - radius, posy - radius + i).OwnerID
            if id and id ~= ID then return true end

            id = getTile(tiles, posx - radius + i, posy + i).OwnerID
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
    local currentTile = getTile(tiles, pos.x, pos.y)

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
            tileHashValue = ((tileHashValue + 1) * (getTile(world.Tiles, x, y).Type + 1) * x * y) % 1677216
        end
    end

    local unitHashValue = 0

    for id, unit in pairs(world.Units) do 
        unitHashValue = ((unitHashValue + 1) * (unit.Type + 1 * unit.Position.x * unit.Position.y) * unit.OwnerID) % 1677216
    end

    local hash = string.format("%08x%08x", tileHashValue, unitHashValue)

    return hash
end

World.getTile = getTile
World.setTile = setTile

return World