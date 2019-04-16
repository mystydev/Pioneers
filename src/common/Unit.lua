
local Unit = {}

local HttpService = game:GetService("HttpService")

Unit.NONE     = 0
Unit.VILLAGER = 1
Unit.SOLDIER  = 2

Unit.Localisation = {}
Unit.Localisation[Unit.NONE]     = "Unknown Unit"
Unit.Localisation[Unit.VILLAGER] = "Villager"
Unit.Localisation[Unit.SOLDIER]  = "Soldier"

Unit.UnitState = {}
Unit.UnitState.IDLE    = 0
Unit.UnitState.DEAD    = 1
Unit.UnitState.MOVING  = 2
Unit.UnitState.WORKING = 3
Unit.UnitState.RESTING = 4
Unit.UnitState.STORING = 5

Unit.StateLocalisation = {}
Unit.StateLocalisation[Unit.UnitState.IDLE]    = "Idle"
Unit.StateLocalisation[Unit.UnitState.DEAD]    = "Dead"
Unit.StateLocalisation[Unit.UnitState.MOVING]  = "Moving"
Unit.StateLocalisation[Unit.UnitState.WORKING] = "Working"
Unit.StateLocalisation[Unit.UnitState.RESTING] = "Resting"
Unit.StateLocalisation[Unit.UnitState.STORING] = "Storing"

function Unit.serialise(unit)
    local index = unit.Id
    local data = {}

    data.Type    = unit.Type
    data.Id      = unit.Id
    data.OwnerId = unit.OwnerId
    data.Posx    = unit.Position.x
    data.Posy    = unit.Position.y
    data.Health  = unit.Health 
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

function Unit.deserialise(index, sdata, tiles)
    local data = HttpService:JSONDecode(sdata)
    local unit = {}

    unit.Type     = data.Type
    unit.Id       = index
    unit.OwnerId  = data.OwnerId
    unit.Position = Vector2.new(data.Posx, data.Posy)
    unit.Health   = data.Health
    unit.Fatigue  = data.Fatigue
    unit.Home     = tiles[data.Home]
    unit.Work     = tiles[data.Work]
    unit.Target   = tiles[data.Target]
    unit.State    = data.State

    return unit
end

return Unit