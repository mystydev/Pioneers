
local Unit = {}

local HttpService = game:GetService("HttpService")

Unit.NONE = 0
Unit.VILLAGER = 1
Unit.SOLDIER = 2

Unit.HighestCount = 2

function Unit.new(Type, ID, OwnerID, Position, Health, Fatigue, Home, Work, Target, HeldResource)
    local new = {}

    new.Type = Type
    new.ID = ID
    new.OwnerID = OwnerID
    new.Position = Position
    new.Health = Health
    new.Fatigue = Fatigue
    new.Home = Home
    new.Work = Work
    new.Target = Target
    new.HeldResource = HeldResource

    print(ID, Unit.HighestCount)
    Unit.HighestCount = Unit.HighestCount + 1

    return new
end

function Unit.serialise(unit)
    local index = unit.ID
    local data = {}

    data.Type = unit.Type
    data.ID = unit.ID
    data.OwnerId = unit.OwnerID
    data.Posx = unit.Position.x
    data.Posy = unit.Position.y
    data.Health = unit.Health 
    data.Fatigue = unit.Fatigue

    data.Home = string.format("%d:%d", unit.Home.Position.x, unit.Home.Position.y)
    if unit.Work then
        data.Work = string.format("%d:%d", unit.Work.Position.x, unit.Work.Position.y)
    end
    if unit.Target then
        data.Target = string.format("%d:%d", unit.Target.Position.x, unit.Target.Position.y)
    end

    return HttpService:JSONEncode({index = index, data = data})
end

function Unit.deserialise(index, data, tiles)
    local data = HttpService:JSONDecode(data)
    local unit = {}

    unit.Type = data.Type
    unit.ID = index
    unit.OwnerID = data.OwnerId
    unit.Position = Vector3.new(data.Posx, data.Posy, 0)
    unit.Health = data.Health
    unit.Fatigue = data.Fatigue
    unit.Home = tiles[data.Home]
    unit.Work = tiles[data.Work]
    unit.Target = tiles[data.Target]
    unit.State = data.State

    count = tonumber(string.split(index, ":")[2])
    if count and count > Unit.HighestCount then
        Unit.HighestCount = count
    end

    return unit
end

return Unit