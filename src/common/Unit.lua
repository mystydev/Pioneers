
local Unit = {}

Unit.NONE = 0
Unit.VILLAGER = 1
Unit.SOLDIER = 2

function Unit.new(Type, ID, OwnerID, Position, Health, Fatigue, Home, Work, Target, HeldResource)
    local new = {}

    new.Type = Type
    new.ID = ID
    new.OwnerID = OwnerID
    new.Position = Position
    new.Health = Health
    new.Fatigue = Fatigue
    new.Home = Home
    new.Work = Work
    new.Target = Target
    new.HeldResource = HeldResource

    return new
end

return Unit