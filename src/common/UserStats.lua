
local UserStats = {}

function UserStats.new(Food, Wood, Stone, PlayerID, Population, MaxPopulation)
    local new = {}

    new.Food = Food
    new.Wood = Wood
    new.Stone = Stone
    new.PlayerID = PlayerID
    new.Population = Population
    new.MaxPopulation = MaxPopulation
    new.changed = function() end

    return new
end

function UserStats.hasEnoughResources(stats, requirement)
    return stats.Food >= (requirement.Food or 0)
        and stats.Wood >= (requirement.Wood or 0)
        and stats.Stone >= (requirement.Stone or 0)
end

function UserStats.removeResources(stats, requirement)
    stats.Food  = stats.Food - (requirement.Food or 0)
    stats.Wood  = stats.Wood - (requirement.Wood or 0)
    stats.Stone = stats.Stone - (requirement.Stone or 0)
    stats.changed()
end

return UserStats