
local Roact = require(game.ReplicatedStorage.Roact)

local function Label(props)
    return Roact.createElement("TextLabel", {
        Name                   = "Label",
        Text                   = props.Text or "Unknown",
        BackgroundTransparency = 1,
        Position               = props.Position or UDim2.new(0.5, 0, 0.45, 0),
        Size                   = props.Size or UDim2.new(0.85,0,0.85,0),
        Font                   = props.Font or "SourceSans",
        TextSize               = props.TextSize or 16,
        TextXAlignment         = props.XAlign or "Center",
        TextColor3             = props.Color or Color3.fromRGB(112, 112, 112),
        TextTransparency       = props.TextTransparency,
        TextWrapped            = props.TextWrapped or true,
        ZIndex                 = props.ZIndex or 1,
        AnchorPoint            = props.AnchorPoint or Vector2.new(0.5, 0.5),
    })
end

return Label