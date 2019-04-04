local Replication = {}

local Client = script.Parent
local ViewUnit = require(Client.ViewUnit)
local ViewStats = require(Client.ViewStats)
local Network = game.ReplicatedStorage.Network

local currentWorld
local currentStats

function Replication.getWorldState()
    print("Getting world state")
    currentWorld = Network.RequestWorldState:InvokeServer()
    return currentWorld
end

function Replication.getUserStats()
    currentStats = Network.RequestStats:InvokeServer()
    return currentStats
end

local function handleUnitUpdate(unit)
    local localUnit = currentWorld.Units[unit.ID]
    
    for i, v in pairs(unit) do
        localUnit[i] = v
    end

    ViewUnit.updateDisplay(localUnit)
end

local function handleStatsUpdate(stats)
    for i, v in pairs(stats) do
        currentStats[i] = v
    end

    currentStats.changed()
end

Network.UnitUpdate.OnClientEvent:Connect(handleUnitUpdate)
Network.StatsUpdate.OnClientEvent:Connect(handleStatsUpdate)

return Replication