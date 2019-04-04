
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
    {Stone =  10, Wood =   0}, -- path
    {Stone =  10, Wood =  20}, -- house
    {Stone =   6, Wood =   9}, -- farm
    {Stone =   0, Wood =  15}, -- mine
    {Stone =  15, Wood =   0}, -- forestry
    {Stone =  30, Wood =  50}, -- storage
    {Stone =  50, Wood = 100}, -- barracks
    {Stone = 400, Wood =  20}, -- wall
    {Stone = 400, Wood = 100}  -- gate
}   

function Tile.new(Type, OwnerID, Position, Health)
    local new = {}

    new.Type = Type
    new.OwnerID = OwnerID
    new.Position = Position
    new.Health = Health

    return new
end

function Tile.serialisable(tile)
    rep = {}
    rep.T = tile.Type ~= Tile.GRASS and tile.Type or nil
    rep.O = tile.OwnerID
    rep.P = {tile.Position.x, tile.Position.y}
    rep.H = tile.Type ~= Tile.GRASS and tile.Health or nil

    return rep
end

function Tile.deserialise(data)
    return Tile.new(
        data.T or Tile.GRASS,
        data.O,
        Vector2.new(data.P.x, data.P.y),
        data.H
    )
end

return Tile