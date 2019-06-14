local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local InfoDrop = require(ui.InfoDrop)

local green  = Color3.fromHSV(0.3405, 0.5812, 0.6275)
local orange = Color3.fromHSV(0.0587, 1.0000, 0.9020)
local red    = Color3.fromHSV(0.0000, 0.8470, 0.7176)

local function StatusBar(props)

    local percent = props.ValPercent or 1
    local barColor

    --if props.ValPercent < 0.5 then
        --barColor = props.StartCol:Lerp(props.MidCol, percent*2)
    --else
        --barColor = props.MidCol:Lerp(props.EndCol, percent*2 - 1)
    --end

    barColor = props.StartCol

    return Roact.createElement("Frame", {
        Name                   = "StatusBar",
        BackgroundTransparency = 0.5,
        Position               = props.Position,
        Size                   = props.Size,
        BackgroundColor3       = Color3.fromRGB(143, 143, 143),
        BorderSizePixel        = 0,
        }, {
            Roact.createElement("Frame", {
                Name = "StatusIndicator",
                BackgroundTransparency = 0,
                Size                   = UDim2.new(percent, 0, 1, 0),
                BackgroundColor3       = barColor,
                BorderSizePixel        = 0,
            }, {
                Roact.createElement(InfoDrop, {
                    Position = UDim2.new(1, 0, 0, 0),
                    Color    = barColor,
                    Text     = props.Value,
                    TextColor = Color3.new(1,1,1),
                })
            })
        })
end

return StatusBar