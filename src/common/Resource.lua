
local Resource = {}

function Resource.new(Type, Amount)
    local new = {}

    new.Type = Type
    new.Amount = Amount

    return new
end

return Resource