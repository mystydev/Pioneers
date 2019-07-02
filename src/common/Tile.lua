
local Tile = {}

local HttpService = game:GetService("HttpService")

Tile.DESTROYED = -1
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

Tile.NumberTypes = 10

Tile.Localisation = {}
Tile.Localisation[Tile.DESTROYED]= "Ruins"
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
    {Stone =   0,   Wood =   0}, -- keep
    {Stone =  20,   Wood =   0}, -- path
    {Stone =  100,  Wood =  100}, -- house
    {Stone =  75,   Wood =  75}, -- farm
    {Stone =   0,   Wood =  150}, -- mine
    {Stone =  150,  Wood =   0}, -- forestry
    {Stone = 500,   Wood = 500}, -- storage
    {Stone = 500,  Wood = 300}, -- barracks
    {Stone = 1000, Wood =  1000}, -- wall
    {Stone = 1000, Wood = 1500}  -- gate
}   

Tile.MaxHealth = {}
Tile.MaxHealth[Tile.DESTROYED]= 0
Tile.MaxHealth[Tile.GRASS]    = 0
Tile.MaxHealth[Tile.KEEP]     = 1000
Tile.MaxHealth[Tile.PATH]     = 100
Tile.MaxHealth[Tile.HOUSE]    = 200
Tile.MaxHealth[Tile.FARM]     = 100
Tile.MaxHealth[Tile.MINE]     = 100
Tile.MaxHealth[Tile.FORESTRY] = 100
Tile.MaxHealth[Tile.STORAGE]  = 300
Tile.MaxHealth[Tile.BARRACKS] = 1000
Tile.MaxHealth[Tile.WALL]     = 10000
Tile.MaxHealth[Tile.GATE]     = 10000 

function Tile.serialise(tile)
    local index = string.format("%d:%d", tile.Position.x, tile.Position.y)
    local data = {}

    data.Type = tile.Type
    data.OwnerId = tile.OwnerId

    return HttpService:JSONEncode({index = index, data = data})
end

function Tile.deserialise(index, data)
    local data    = HttpService:JSONDecode(data)
    local tile    = {}
    local x, y    = unpack(string.split(index, ':'))

    tile.Type     = data.Type
    tile.OwnerId  = data.OwnerId
    tile.Position = Vector2.new(tonumber(x), tonumber(y))
    tile.Health   = data.Health
    tile.MHealth  = data.MHealth or Tile.MaxHealth[data.Type]
    tile.UnitList = data.UnitList

    return tile
end

function Tile.getIndex(tile)
    if tile.Position then
        return string.format("%d:%d", tile.Position.x, tile.Position.y)
    end
end

return Tile