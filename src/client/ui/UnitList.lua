local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local UnitInfoLabel = require(ui.UnitInfoLabel)

local function UnitList(props)

    local units = {}

    for id, unit in pairs(props.World.Units) do
        if unit.Home.Position == props.Obj.Position then
            table.insert(units, unit)
        end
    end

    local unitLabels = {}

    for i, unit in pairs(units) do
        table.insert(unitLabels, Roact.createElement(UnitInfoLabel, {
                                    Position = UDim2.new(0.5, 0, 0, 42 * i),
                                    Unit = unit,
        }))
    end

    return Roact.createElement("Frame", {
        Name = "UnitList",
        BackgroundTransparency = 1,
        Position = props.Position or UDim2.new(0.146, 0, 0.4, 0),
        Size = UDim2.new(0, 239, 0, 73),
    }, unitLabels)
end

return UnitList