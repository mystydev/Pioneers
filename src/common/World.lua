local World  = {}
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile = require(Common.Tile)

local format = string.format

World.Actions = {NEW_PLAYER = 0, PLACE_TILE = 1, SET_WORK = 2, ATTACK = 3, DELETE_TILE = 4, REPAIR_TILE = 5, DELETE_KINGDOM = 6}
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

function World.getNeighbours(tiles, pos)
    return {
        World.getTileXY(tiles, pos.x    , pos.y + 1),
        World.getTileXY(tiles, pos.x + 1, pos.y + 1),
        World.getTileXY(tiles, pos.x + 1, pos.y    ),
        World.getTileXY(tiles, pos.x    , pos.y - 1),
        World.getTileXY(tiles, pos.x - 1, pos.y - 1),
        World.getTileXY(tiles, pos.x - 1, pos.y    ),
    }
end

function World.getClosestStorageToTile(tiles, pos)
    local searchQueue = {}
    local index = 0
    local current = World.getTileXY(tiles, pos.x, pos.y)
    local distance = {}
    distance[current] = 0

    while current do
        local neighbours = World.getNeighbours(tiles, current.Position)
        local dist = distance[current] + 1

        for _, neighbour in pairs(neighbours) do
            if (not distance[neighbour] or distance[neighbour] > dist) then

                distance[neighbour] = dist

                if Tile.isStorageTile(neighbour) then
                    return neighbour, dist
                elseif Tile.isWalkable(neighbour) then
                    table.insert(searchQueue, neighbour)
                end
            end
        end

        index = index + 1
        current = searchQueue[index]
    end

    error("Failed to find closest storage tile to ", pos, " (", current, ")")
end

--Returns false if too far
function World.canAssignWorker(tiles, tile, maxDistance)
    if not Tile.isProductivityTile(tile) then
        return
    end

    if tile.UnitList and #tile.UnitList > 0 then
        return
    end

    local _, distance = World.getClosestStorageToTile(tiles, tile.Position)

    if distance > 15 then
        return false
    end

    return true
end


return World