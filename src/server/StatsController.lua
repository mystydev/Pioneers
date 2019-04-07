local StatsController = {}
local Server          = script.Parent
local Common          = game.ReplicatedStorage.Pioneers.Common

local Replication = require(Server.Replication)
local Resource    = require(Common.Resource)
local UserStats   = require(Common.UserStats)

function StatsController.addNewPlayer(player)
    local stats = UserStats.new(500, 500, 500, player.UserId, 0, 0)
    UserStats.Store[player.UserId] = stats

    print("Added id:", player.UserId)

    return stats
end

function StatsController.addResource(ID, resource)
    local stats = UserStats.Store[ID]

    if resource.Type == Resource.FOOD then
        stats.Food = stats.Food + resource.Amount
    elseif resource.Type == Resource.WOOD then
        stats.Wood = stats.Wood + resource.Amount
    elseif resource.Type == Resource.STONE then
        stats.Stone = stats.Stone + resource.Amount
    end

    Replication.pushStatsChange(stats)
end

function StatsController.useResource(ID, resource)
    local stats = UserStats.Store[ID]

    if resource.Type == Resource.FOOD and stats.Food > resource.Amount then
        stats.Food = stats.Food - resource.Amount
    elseif resource.Type == Resource.WOOD and stats.Wood > resource.Amount  then
        stats.Wood = stats.Wood - resource.Amount
    elseif resource.Type == Resource.STONE and stats.Stone > resource.Amount  then
        stats.Stone = stats.Stone - resource.Amount
    else
        return false
    end

    Replication.pushStatsChange(stats)

    return true
end

function StatsController.useRequirement(ID, requirement) --condensed resource list for ease of use
    local stats = UserStats.Store[ID]
    
    stats.Food  = stats.Food - (requirement.Food or 0)
    stats.Wood  = stats.Wood - (requirement.Wood or 0)
    stats.Stone = stats.Stone - (requirement.Stone or 0)

    Replication.pushStatsChange(stats)
end

return StatsController