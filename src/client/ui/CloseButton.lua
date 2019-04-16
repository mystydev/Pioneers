
local Roact = require(game.ReplicatedStorage.Roact)

local function CloseButton(props)
    return Roact.createElement("TextLabel", {
        Name                   = "CloseButton",
        Text                   = "Close",
        BackgroundTransparency = 1,
        Position               = props.Position,
        Size                   = UDim2.new(0,100,0,48),
        Font                   = "SourceSansLight",
        TextSize               = 24,
        TextTransparency       = 0.4
    })
end

return CloseButton