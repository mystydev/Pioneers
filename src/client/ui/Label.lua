
local Roact = require(game.ReplicatedStorage.Roact)

local function Label(props)
    return Roact.createElement("TextLabel", {
        Name                   = "Label",
        Text                   = props.Text or "Unknown",
        BackgroundTransparency = 1,
        Position               = props.Position or UDim2.new(0, 0, 0, 0),
        Size                   = props.Size or UDim2.new(1,0,1,0),
        Font                   = props.Font or "SourceSans",
        TextSize               = props.TextSize or 16,
        TextXAlignment         = props.XAlign or "Center",
        TextColor3             = props.Color or Color3.fromRGB(61,61,61),
        TextTransparency       = props.TextTransparency,
        ZIndex                 = props.ZIndex or 1,
    })
end

return Label