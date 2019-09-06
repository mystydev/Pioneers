
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
Tile.OTHERPLAYER = 1000

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

Tile.Description = {}
Tile.Description[Tile.KEEP]     = "The foundation and heart of a civilisation"
Tile.Description[Tile.PATH]     = "Pave down some stone where villagers can walk"
Tile.Description[Tile.HOUSE]    = "A cosy place for villagers to live and rest"
Tile.Description[Tile.FARM]     = "Everyone needs some food, this is where it's made"
Tile.Description[Tile.MINE]     = "Smash up some stone to use it elsewhere"
Tile.Description[Tile.FORESTRY] = "Chop down trees to build with"
Tile.Description[Tile.STORAGE]  = "All this stuff has to go somewhere"
Tile.Description[Tile.BARRACKS] = "Train villagers how to attack others"
Tile.Description[Tile.WALL]     = "Keep your villagers safe from hostile enemies"
Tile.Description[Tile.GATE]     = "As safe as a wall but now villagers can freely move" 

Tile.ConstructionCosts = {}
Tile.ConstructionCosts[Tile.KEEP]     = {Stone =   0,   Wood =    0}
Tile.ConstructionCosts[Tile.PATH]     = {Stone =   20,  Wood =    0}
Tile.ConstructionCosts[Tile.HOUSE]    = {Stone =  100,  Wood =  100}
Tile.ConstructionCosts[Tile.FARM]     = {Stone =   75,  Wood =   75}
Tile.ConstructionCosts[Tile.MINE]     = {Stone =    0,  Wood =  150}
Tile.ConstructionCosts[Tile.FORESTRY] = {Stone =  150,  Wood =    0}
Tile.ConstructionCosts[Tile.STORAGE]  = {Stone =  500,  Wood =  500}
Tile.ConstructionCosts[Tile.BARRACKS] = {Stone =  500,  Wood =  300}
Tile.ConstructionCosts[Tile.WALL]     = {Stone = 1000,  Wood = 1000}
Tile.ConstructionCosts[Tile.GATE]     = {Stone = 1000,  Wood = 1500}

Tile.MaintenanceCosts = {}
Tile.MaintenanceCosts[Tile.KEEP]     = {Stone = 0,  Wood = 0}
Tile.MaintenanceCosts[Tile.PATH]     = {Stone = 0,  Wood = 0}
Tile.MaintenanceCosts[Tile.HOUSE]    = {Stone = 0,  Wood = 0}
Tile.MaintenanceCosts[Tile.FARM]     = {Stone = 0,  Wood = 0}
Tile.MaintenanceCosts[Tile.MINE]     = {Stone = 0,  Wood = 0}
Tile.MaintenanceCosts[Tile.FORESTRY] = {Stone = 0,  Wood = 0}
Tile.MaintenanceCosts[Tile.STORAGE]  = {Stone = 1,  Wood = 1}
Tile.MaintenanceCosts[Tile.BARRACKS] = {Stone = 2,  Wood = 2}
Tile.MaintenanceCosts[Tile.WALL]     = {Stone = 3,  Wood = 3}
Tile.MaintenanceCosts[Tile.GATE]     = {Stone = 3,  Wood = 3}

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
    --local data    = HttpService:JSONDecode(data)
    --[[local tile    = {}
    local x, y    = unpack(string.split(index, ':'))

    tile.Type     = data.Type
    tile.OwnerId  = data.OwnerId
    tile.Position = Vector2.new(tonumber(x), tonumber(y))
    tile.Health   = data.Health
    tile.MHealth  = data.MHealth or Tile.MaxHealth[data.Type]
    tile.UnitList = data.UnitList]]--

    local x, y    = unpack(string.split(index, ':'))

    data.Type = tonumber(data.Type)
    data.OwnerId  = tonumber(data.OwnerId)
    data.Health = tonumber(data.Health)
    data.MHealth  = data.MHealth or Tile.MaxHealth[data.Type]
    data.Position = Vector2.new(tonumber(x), tonumber(y))

    if not data.UnitList or data.UnitList == "" then
        data.UnitList = {}
    end

    return data
end

function Tile.isDifferent(original, other)
    local hasDifference = false

    for i, v in pairs(other) do --Check members of other table
        if original[i] ~= v then
            if type(v) == "table" then --If it is a table then we do a slightly deeper shallow check (for UnitList)
                --for i2, v2 in pairs(v) do
                --    if original[i][i2] ~= v2 then
                --        return true
                --    end
                --end
                if (#v ~= #original[i]) then
                    return true
                end
            else
                return true
            end
        end
    end
end

function Tile.defaultGrass(pos)
    return Tile.deserialise(pos, "{\"Type\":0}")
end

function Tile.getIndex(tile)
    if tile and tile.Position then
        return string.format("%d:%d", tile.Position.x, tile.Position.y)
    end
end

function Tile.canAssignWorker(tile)
    if not Tile.isProductivityTile(tile) then
        return end

    if not tile.UnitList or #tile.UnitList == 0 then
        return true
    end

    return false
end

function Tile.isProductivityTile(tile)
    return tile.Type == Tile.FARM or tile.Type == Tile.FORESTRY or tile.Type == Tile.MINE or tile.Type == Tile.BARRACKS
end

return Tile