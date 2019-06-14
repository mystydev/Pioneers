
local Unit = {}

local HttpService = game:GetService("HttpService")

Unit.NONE       = 0
Unit.VILLAGER   = 1
Unit.FARMER     = 2
Unit.LUMBERJACK = 3
Unit.MINER      = 4
Unit.APPRENTICE = 5
Unit.SOLDIER    = 6

Unit.Localisation = {}
Unit.Localisation[Unit.NONE]       = "Unknown Unit"
Unit.Localisation[Unit.VILLAGER]   = "Villager"
Unit.Localisation[Unit.FARMER]     = "Farmer"
Unit.Localisation[Unit.LUMBERJACK] = "Lumberjack"
Unit.Localisation[Unit.MINER]      = "Miner"
Unit.Localisation[Unit.APPRENTICE] = "Apprentice"
Unit.Localisation[Unit.SOLDIER]    = "Soldier"

Unit.UnitState = {}
Unit.UnitState.IDLE    = 0
Unit.UnitState.DEAD    = 1
Unit.UnitState.MOVING  = 2
Unit.UnitState.WORKING = 3
Unit.UnitState.RESTING = 4
Unit.UnitState.STORING = 5
Unit.UnitState.COMBAT  = 6
Unit.UnitState.LOST    = 7

Unit.StateLocalisation = {}
Unit.StateLocalisation[Unit.UnitState.IDLE]    = "Idle"
Unit.StateLocalisation[Unit.UnitState.DEAD]    = "Dead"
Unit.StateLocalisation[Unit.UnitState.MOVING]  = "Moving"
Unit.StateLocalisation[Unit.UnitState.WORKING] = "Working"
Unit.StateLocalisation[Unit.UnitState.RESTING] = "Resting"
Unit.StateLocalisation[Unit.UnitState.STORING] = "Storing"
Unit.StateLocalisation[Unit.UnitState.COMBAT]  = "In Combat"
Unit.StateLocalisation[Unit.UnitState.LOST]    = "Lost"

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
    unit.MHealth  = data.MHealth or 200
    unit.Fatigue  = data.Fatigue
    unit.MFatigue = data.MFatigue or 10
    unit.Training = data.Training
    unit.MTraining= data.MTraining or 10000
    unit.Home     = tiles[data.Home]
    unit.Work     = tiles[data.Work] or {Type = 0}
    unit.Target   = tiles[data.Target]
    unit.Attack   = tiles[data.Attack]
    unit.State    = data.State
    unit.HeldResource = data.HeldResource or false

    return unit
end

function Unit.isMilitary(unit)
    return unit.Type == Unit.APPRENTICE or unit.Type == Unit.SOLDIER
end

return Unit