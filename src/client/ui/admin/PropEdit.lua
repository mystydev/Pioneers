local ui       = script.Parent.Parent
local Roact    = require(game.ReplicatedStorage.Roact)

local Label    = require(ui.Label)
local propEdit = Roact.Component:extend("propEdit")

function propEdit:init()

end

function propEdit:render()

    local index = Roact.createElement(Label, {
        Size = UDim2.new(1, 0, 0, 20),
        Text = self.props.Index,
        Color = Color3.fromRGB(200, 200, 200),
        XAlign = "Left"
    })

    local value = Roact.createElement(Label, {
        Size = UDim2.new(1, 0, 0, 20),
        Text = self.props.Value,
        Color = Color3.fromRGB(200, 200, 200),
        XAlign = "Right"
    })

    return Roact.createElement("Frame", {
        Size = UDim2.new(0.9, 0, 0, 20),
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,0),
        AnchorPoint = Vector2.new(0, 0),
    }, {index, value})
end

return propEdit