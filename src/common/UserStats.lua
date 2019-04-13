
local UserStats = {}

UserStats.Store = {}

function UserStats.new(Food, Wood, Stone, PlayerId, Population, MaxPopulation)
    local new = {}

    new.Food = Food
    new.Wood = Wood
    new.Stone = Stone
    new.PlayerId = PlayerId
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

return UserStats