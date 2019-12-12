
local Roact = require(game.ReplicatedStorage.Roact)

local function Title(props)
    return Roact.createElement("TextLabel", {
        Name                   = "Title",
        Text                   = props.Title or "Unknown",
        TextTransparency       = props.TextTransparency or 0,
        BackgroundTransparency = 1,
        Position               = props.Position or UDim2.new(0.5, 0, 0, 48),
        Size                   = props.Size or UDim2.new(0,200,0,32),
        Font                   = "SourceSans",
        TextSize               = props.TextSize or 48,
        TextColor3             = props.Color or Color3.fromRGB(112, 112, 112),
        TextXAlignment         = props.TextXAlignment or "Center",
        AnchorPoint            = props.AnchorPoint or Vector2.new(0.5, 0.5),
    }, props[Roact.Children])
end

return Title