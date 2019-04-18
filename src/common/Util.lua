local Util   = {}
local Common = game.ReplicatedStorage.Pioneers.Common

local World = require(Common.World)

local TILESPACING = 10 --Distance from center of hexagon to edge vertex
local EDGESPACING = TILESPACING * (0.5 * 3^.5)

local YOFFSET = EDGESPACING * 2 * Vector3.new(1, 0, 0)
local XOFFSET = EDGESPACING * 2 * Vector3.new(-0.5, 0, 0.866)

local getTile = World.getTile
local format = string.format

function Util.axialCoordToWorldCoord(position)
    return position.y * YOFFSET + position.x * XOFFSET
end

function Util.worldCoordToAxialCoord(position)

    local x = math.floor(position.z / XOFFSET.z + 0.5)
    local y = math.floor((position.x - XOFFSET.x * x) / YOFFSET.x + 0.5)

    return Vector2.new(x, y)
end

function Util.circularCollection(tiles, posx, posy, startRadius, endRadius)

    local collection = {}

    if startRadius == 0 then
        table.insert(collection, getTile(tiles, posx, posy))
    end

    for radius = startRadius, endRadius do
        for i = 0, radius-1 do
            table.insert(collection, getTile(tiles, posx +          i, posy +     radius))
            table.insert(collection, getTile(tiles, posx +     radius, posy + radius - i))
            table.insert(collection, getTile(tiles, posx + radius - i, posy -          i))
            table.insert(collection, getTile(tiles, posx -          i, posy -     radius))
            table.insert(collection, getTile(tiles, posx -     radius, posy - radius + i))
            table.insert(collection, getTile(tiles, posx - radius + i, posy +          i))
        end
    end

    return collection
end

return Util