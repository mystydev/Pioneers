
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
    new.Unlocked = {}

    return new
end

function UserStats.hasEnoughResources(stats, requirement)
    return tonumber(stats.Food or 0) >= (requirement.Food or 0)
        and tonumber(stats.Wood or 0) >= (requirement.Wood or 0)
        and tonumber(stats.Stone or 0) >= (requirement.Stone or 0)
end

function UserStats.hasUnlocked(stats, tileType)

    for _, v in pairs(stats.Unlocked) do
        if tonumber(v) == tonumber(tileType) then
            return true
        end
    end

    return false
end

return UserStats