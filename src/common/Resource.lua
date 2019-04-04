
local Resource = {}

Resource.FOOD = 0
Resource.WOOD = 1
Resource.STONE = 2

Resource.Localisation = {}
Resource.Localisation[Resource.FOOD] = "Food"
Resource.Localisation[Resource.WOOD] = "Wood"
Resource.Localisation[Resource.STONE] = "Stone"

function Resource.new(Type, Amount)
    local new = {}

    new.Type = Type
    new.Amount = Amount

    return new
end

return Resource