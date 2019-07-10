
local Roact = require(game.ReplicatedStorage.Roact)

local function Title(props)
    return Roact.createElement("TextLabel", {
        Name                   = "Title",
        Text                   = props.Title or "Unknown",
        TextTransparency       = props.TextTransparency or 0,
        BackgroundTransparency = 1,
        Position               = props.Position or UDim2.new(0, 50, 0, 30),
        Size                   = props.Size or UDim2.new(0,200,0,32),
        Font                   = "SourceSans",
        TextSize               = props.TextSize or 36,
        TextColor3             = Color3.fromRGB(61,61,61),
        TextXAlignment         = props.TextXAlignment or "Left",
        AnchorPoint            = props.AnchorPoint or Vector2.new(0,0),
    })
end

return Title