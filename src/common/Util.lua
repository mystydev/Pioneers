local Util = {}

local TILESPACING = 10 --Distance from center of hexagon to edge vertex
local EDGESPACING = TILESPACING * (0.5 * 3^.5)

local YOFFSET = EDGESPACING * 2 * Vector3.new(1, 0, 0)
local XOFFSET = EDGESPACING * 2 * Vector3.new(-0.5, 0, 0.866)

function Util.axialCoordToWorldCoord(position)
    return position.y * YOFFSET + position.x * XOFFSET
end

function Util.worldCoordToAxialCoord(position)

    local x = math.floor(position.z / XOFFSET.z + 0.5)
    local y = math.floor((position.x - XOFFSET.x * x) / YOFFSET.x + 0.5)

    return Vector3.new(x, y, 0)
end

return Util