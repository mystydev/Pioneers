
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

function Tile.serialise(tile)
    local index = string.format("%d:%d", tile.Position.x, tile.Position.y)
    local data = {}

    data.Type = tile.Type
    data.OwnerId = tile.OwnerId

    return HttpService:JSONEncode({index = index, data = data})
end

function Tile.deserialise(index, data)
    local data = HttpService:JSONDecode(data)
    local tile = {}

    local x, y = unpack(string.split(index, ':'))
    tile.Type = data.Type
    tile.OwnerId = data.OwnerId
    tile.Position = Vector2.new(tonumber(x), tonumber(y))
    tile.Health = data.Health
    tile.unitlist = data.unitlist

    return tile
end

function Tile.getIndex(tile)
    return string.format("%d:%d", tile.Position.x, tile.Position.y)
end

return Tile