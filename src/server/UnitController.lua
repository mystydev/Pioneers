local UnitController = {}

local Server = script.Parent
local Replication = require(Server.Replication)

function UnitController.AssignPosition(unit, position)
    unit.Position = position
    Replication.pushUnitChange(unit)
end

function UnitController.AddResource(unit, resource)
    local heldResource = unit.HeldResource

    if heldResource then
        if heldResource.Type == resource.Type then
            heldResource.Amount = heldResource.Amount + resource.Amount
        else
            print("Tried to add resource to unit when unit has a different resource!")
        end
    else
        unit.HeldResource = resource
    end

    Replication.pushUnitChange(unit)
end

return UnitController