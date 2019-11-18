local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local DefaultFrame = require(ui.common.DefaultFrame)
local Button = require(ui.common.Button)
local Title = require(ui.Title)
local Label = require(ui.Label)
local TweenService = game:GetService("TweenService")

local fade = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function DefaultPrompt(props)
    local elements = {}

    if props.Buttons then
        local buttonRatio = 0.5 / (#props.Buttons)

        for i, v in pairs(props.Buttons) do
            elements[i] = Roact.createElement(Button, {
                Text  = v.Text,
                Color = v.Color,
                Position = UDim2.new(buttonRatio + (i - 1) * 2 * buttonRatio, 0, 0.8, 0),
                ClickEvent = v.Event,
            })
        end
    end

    elements.title = Roact.createElement(Title, {
        Title = props.Title,
    })

    elements.label = Roact.createElement(Label, {
        Text = props.Text,
        TextSize = 32,
    })

    return Roact.createElement(DefaultFrame, {
        Position = props.Position or UDim2.new(0.5, 0, 0.5, 0),
        Size     = props.Size or UDim2.new(0, 550, 0, 350),
    }, elements)
end

return DefaultPrompt