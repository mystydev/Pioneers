local ui = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local ResourceLabel = require(ui.ResourceLabel)

local function StatsPanel(props)

    local elements = {}
    local stats = props.stats

    elements.FoodLabel = Roact.createElement(ResourceLabel, {Position = UDim2.new(0, 20, 1, -20), Type = "Food", stats = stats})
    elements.WoodLabel = Roact.createElement(ResourceLabel, {Position = UDim2.new(0, 208 + 30, 1, -20), Type = "Wood", stats = stats})
    elements.StoneLabel = Roact.createElement(ResourceLabel, {Position = UDim2.new(0, 2 * 208 + 40, 1, -20), Type = "Stone", stats = stats})

    return Roact.createElement("Frame", {
        Name                   = "StatsPanel",
        Position               = UDim2.new(0, 0, 1, 0),
        Size                   = UDim2.new(0, 500, 0, 200),
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(0, 1)
    }, elements)
end

return StatsPanel