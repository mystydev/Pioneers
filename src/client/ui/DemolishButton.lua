
local Roact = require(game.ReplicatedStorage.Roact)

local function CloseButton(props)
    return Roact.createElement("TextLabel", {
        Name                   = "DemolishButton",
        Text                   = "Delete",
        BackgroundTransparency = 1,
        Position               = props.Position,
        Size                   = UDim2.new(0,100,0,48),
        Font                   = "SourceSansLight",
        TextSize               = 24,
        TextTransparency       = 0.4,
        TextColor3             = Color3.fromRGB(170, 0, 0)
    })
end

return CloseButton