local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local Label = require(ui.Label)

local function InfoDrop(props)
    return Roact.createElement("ImageLabel", {
        Name                   = "InfoDrop",
        BackgroundTransparency = 1,
        ImageColor3            = props.Color,
        Position               = props.Position,
        Size                   = UDim2.new(0,36,0,41),
        Image                  = "rbxassetid://3063804359",
        AnchorPoint            = Vector2.new(0.5, 1),
        ZIndex = 2,
    },{
        Label = Roact.createElement(Label, {
            Text = props.Text,
            Color = props.TextColor,
            Position = UDim2.new(0, 0, 0, -5),
            TextTransparency = 0.2,
            Font = "SourceSansBold",
            ZIndex = 2,
        })
    }

)
end

return InfoDrop