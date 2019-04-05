
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

Tile.Localisation = {}
Tile.Localisation[Tile.GRASS]    = "Grass"
Tile.Localisation[Tile.KEEP]     = "Keep"
Tile.Localisation[Tile.PATH]     = "Path"
Tile.Localisation[Tile.HOUSE]    = "House"
Tile.Localisation[Tile.FARM]     = "Farm"
Tile.Localisation[Tile.MINE]     = "Mine"
Tile.Localisation[Tile.FORESTRY] = "Forestry"
Tile.Localisation[Tile.STORAGE]  = "Storage"
Tile.Localisation[Tile.BARRACKS] = "Barracks"
Tile.Localisation[Tile.WALL]     = "Wall"
Tile.Localisation[Tile.GATE]     = "Gate" 

Tile.ConstructionCosts = {
    {Stone =   0, Wood =   0}, -- keep
    {Stone =  30, Wood =   0}, -- path
    {Stone =  30, Wood =  60}, -- house
    {Stone =  20, Wood =  40}, -- farm
    {Stone =   0, Wood =  60}, -- mine
    {Stone =  60, Wood =   0}, -- forestry
    {Stone = 200, Wood = 200}, -- storage
    {Stone = 10000, Wood = 10000}, -- barracks
    {Stone = 1000, Wood =  200}, -- wall
    {Stone = 1000, Wood = 400}  -- gate
}   

function Tile.new(Type, OwnerID, Position, Health)
    local new = {}

    new.Type = Type
    new.OwnerID = OwnerID
    new.Position = Position
    new.Health = Health

    return new
end

return Tile