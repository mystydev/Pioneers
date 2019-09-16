local World  = {}
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile = require(Common.Tile)

local format = string.format

World.Actions = {NEW_PLAYER = 0, PLACE_TILE = 1, SET_WORK = 2, ATTACK = 3, DELETE_TILE = 4, REPAIR_TILE = 5}
World.UnitActions = {World.Actions.SET_WORK, World.Actions.ATTACK}

World.ActionLocalisation = {}
World.ActionLocalisation[World.Actions.SET_WORK] = "Assign work"
World.ActionLocalisation[World.Actions.ATTACK]   = "Attack"

function World.new(Tiles, Units)
    local new = {}

    new.Tiles = Tiles or {}
    new.Units = Units or {}

    return new
end

function World.setTileXY(tiles, tile, x, y)
    tiles[format("%d:%d", x, y)] = tile
end

function World.setTile(tiles, tile, p)
    tiles[p] = tile
end

function World.getTileXY(tiles, x, y)
    local pos = format("%d:%d", x, y)
    local tile = tiles[pos]

    if not tile then
        tile = {Type = Tile.GRASS, Position = Vector2.new(x, y)}
        World.setTile(tiles, tile, pos)
    end

    return tile
end

function World.getTile(tiles, pos)
    local tile = tiles[pos]

    if not tile then
        local x, y = unpack(string.split(pos, ':'))
        tile = {Type = Tile.GRASS, Position = Vector2.new(x, y)}
        World.setTile(tiles, tile, pos)
    end

    return tile
end

function World.getUnit(units, id)
    return units[id]
end

function World.convertIdListToUnits(units, idList)
    local unitList = {}

    for _, unitId in pairs(idList) do
        table.insert(unitList, units[unitId])
    end

    return unitList
end

return World