local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local InfoDrop = require(ui.InfoDrop)

local function HealthBar(props)

    local health = props.HealthPercent or 1
    local barColor = Color3.new((0.7 - health), health * 0.7, 0)

    return Roact.createElement("Frame", {
        Name                   = "HealthBar",
        BackgroundTransparency = 0.5,
        Position               = props.Position,
        Size                   = props.Size,
        BackgroundColor3       = Color3.fromRGB(143, 143, 143),
        BorderSizePixel        = 0,
        }, {
            Roact.createElement("Frame", {
                Name = "HealthIndicator",
                BackgroundTransparency = 0,
                Size                   = UDim2.new(health, 0, 1, 0),
                BackgroundColor3       = barColor,
                BorderSizePixel        = 0,
            }, {
                Roact.createElement(InfoDrop, {
                    Position = UDim2.new(1, 0, 0, 0),
                    Color    = barColor,
                    Text     = props.Health,
                    TextColor = Color3.new(1,1,1)
                })
            })
        })
end

return HealthBar