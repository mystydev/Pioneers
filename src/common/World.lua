
local World = {}
local Vector2 = Vector2

World.SIZE = 50 --How big on each axis the world is
                --For example 10 = 0->10 inclusive
                --This uses the axial coordinate system


function World.new(Tiles, Units)
    local new = {}

    new.Tiles = Tiles
    new.Units = Units

    return new
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