
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
    local foodReq = requirement.Food or 0
    local woodReq = requirement.Wood or 0
    local stoneReq = requirement.Stone or 0

    foodReq = foodReq == 0 and -math.huge or foodReq
    woodReq = woodReq == 0 and -math.huge or woodReq
    stoneReq = stoneReq == 0 and -math.huge or stoneReq

    return tonumber(stats.Food or 0) >= foodReq
        and tonumber(stats.Wood or 0) >= woodReq
        and tonumber(stats.Stone or 0) >= stoneReq
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