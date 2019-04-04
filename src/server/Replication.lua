local Replication = {}

local Network = game.ReplicatedStorage.Network
local Players = game:GetService("Players")

local currentWorld
local currentStats

function Replication.assignWorld(w)
    currentWorld = w
end

function Replication.tempAssignStats(s)
    currentStats = s
end

function Replication.pushUnitChange(unit)
    Network.UnitUpdate:FireAllClients(unit)
end

function Replication.pushStatsChange(stats)
    Network.StatsUpdate:FireAllClients(stats)
end

local function worldStateRequest(player)
    return currentWorld
end

local function statsRequest(player)
    return currentStats
end

Network.RequestWorldState.OnServerInvoke = worldStateRequest
Network.RequestStats.OnServerInvoke = statsRequest

return Replication