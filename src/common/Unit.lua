
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
Unit.UnitState.IDLE     = 0
Unit.UnitState.DEAD     = 1
Unit.UnitState.MOVING   = 2
Unit.UnitState.WORKING  = 3
Unit.UnitState.RESTING  = 4
Unit.UnitState.STORING  = 5
Unit.UnitState.TRAINING = 6
Unit.UnitState.GUARDING = 7
Unit.UnitState.COMBAT   = 8
Unit.UnitState.LOST     = 9

Unit.StateLocalisation = {}
Unit.StateLocalisation[Unit.UnitState.IDLE]     = "Idle"
Unit.StateLocalisation[Unit.UnitState.DEAD]     = "Dead"
Unit.StateLocalisation[Unit.UnitState.MOVING]   = "Moving"
Unit.StateLocalisation[Unit.UnitState.WORKING]  = "Working"
Unit.StateLocalisation[Unit.UnitState.RESTING]  = "Resting"
Unit.StateLocalisation[Unit.UnitState.STORING]  = "Storing"
Unit.StateLocalisation[Unit.UnitState.TRAINING] = "Training"
Unit.StateLocalisation[Unit.UnitState.GUARDING] = "Guarding"
Unit.StateLocalisation[Unit.UnitState.COMBAT]   = "In Combat"
Unit.StateLocalisation[Unit.UnitState.LOST]     = "Lost"

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
    data.Home    = unit.Home
    data.Work    = unit.Work
    data.Target  = unit.Target

    return HttpService:JSONEncode({index = index, data = data})
end

function Unit.sanitise(unit, tiles)
    local x, y = unpack(string.split(unit.Position, ':'))
    unit.Position = Vector2.new(tonumber(x), tonumber(y))
    unit.Type     = tonumber(unit.Type)
    unit.OwnerId  = tonumber(unit.OwnerId)
    unit.Health   = tonumber(unit.Health)
    unit.MHealth  = unit.MHealth and tonumber(unit.MHealth) or 200
    unit.Fatigue  = tonumber(unit.Fatigue)
    unit.MFatigue = unit.MFatigue and tonumber(unit.MFatigue) or 10
    unit.Training = tonumber(unit.Training)
    unit.MTraining= unit.MaxTraining and tonumber(unit.MaxTraining) or 100
    unit.State    = tonumber(unit.State)
    unit.HeldResource = unit.HeldResource or false
    unit.HeldAmount = unit.HeldAmount and tonumber(unit.HeldAmount) or 0

    return unit
end

function Unit.isMilitary(unit)
    return unit.Type == Unit.APPRENTICE or unit.Type == Unit.SOLDIER
end

return Unit