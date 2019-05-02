
local Roact = require(game.ReplicatedStorage.Roact)

local function AgreeButton(props)
    return Roact.createElement("TextButton", {
        Name                   = "AgreeButton",
        Text                   = "Agree",
        BackgroundTransparency = 1,
        Position               = props.Position,
        Size                   = UDim2.new(0,100,0,48),
        Font                   = "SourceSans",
        TextColor3             = Color3.fromRGB(33, 150, 243),
        TextSize               = 32,
        TextTransparency       = 0,
        [Roact.Event.MouseButton1Click] = props.Clicked,
    })
end

return AgreeButton