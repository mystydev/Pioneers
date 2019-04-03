
local Resource = {}

Resource.FOOD = 0
Resource.WOOD = 1
Resource.STONE = 2

function Resource.new(Type, Amount)
    local new = {}

    new.Type = Type
    new.Amount = Amount

    return new
end

return Resource