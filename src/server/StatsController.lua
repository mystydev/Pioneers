local StatsController = {}

local Common = game.ReplicatedStorage.Pioneers.Common
local Server = script.Parent
local Resource = require(Common.Resource)
local Replication = require(Server.Replication)

local currentStats

function StatsController.tempAddStats(s)
    currentStats = s
end

function StatsController.AddResource(ID, resource)
    if resource.Type == Resource.FOOD then
        currentStats.Food = currentStats.Food + resource.Amount
    elseif resource.Type == Resource.WOOD then
        currentStats.Wood = currentStats.Wood + resource.Amount
    elseif resource.Type == Resource.STONE then
        currentStats.Stone = currentStats.Stone + resource.Amount
    end

    Replication.pushStatsChange(currentStats)
end



return StatsController