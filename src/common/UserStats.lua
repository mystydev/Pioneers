
local UserStats = {}

function UserStats.new(Resources, PlayerID, Population, MaxPopulation)
    local new = {}

    new.Resources = Resources
    new.PlayerID = PlayerID
    new.Population = Population
    new.MaxPopulation = MaxPopulation

    return new
end

return UserStats