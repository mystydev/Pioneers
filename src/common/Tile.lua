
local Tile = {}

Tile.GRASS = 0
Tile.KEEP = 1
Tile.PATH = 2
Tile.HOUSE = 3
Tile.FARM = 4
Tile.MINE = 5
Tile.FORESTRY = 6
Tile.STORAGE = 7
Tile.BARRACKS = 8
Tile.WALL = 9
Tile.GATE = 10

function Tile.new(Type, OwnerID, Position, Health)
    local new = {}

    new.Type = Type
    new.OwnerId = OwnerID
    new.Position = Position
    new.Health = Health

    return new
end

return Tile