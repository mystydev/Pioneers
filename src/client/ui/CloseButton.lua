local Client = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local UIBase = require(Client.UIBase)

local function CloseButton(props)
    return Roact.createElement("TextButton", {
        Name                   = "CloseButton",
        Text                   = "Close",
        BackgroundTransparency = 1,
        Position               = props.Position,
        Size                   = UDim2.new(0,100,0,48),
        Font                   = "SourceSansLight",
        TextSize               = 24,
        TextTransparency       = 0.4,
        AnchorPoint            = props.AnchorPoint or Vector2.new(0, 0),
        [Roact.Event.MouseButton1Click] = props.OnClick
    })
end

return CloseButton