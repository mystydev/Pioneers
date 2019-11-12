local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local DefaultFrame = require(ui.common.DefaultFrame)
local Button = require(ui.common.Button)
local Title = require(ui.Title)
local Label = require(ui.Label)
local TweenService = game:GetService("TweenService")

local fade = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function AwaitActionPrompt(props)
    local elements = {}

    local buttonRatio = 0.5 / (#props.Buttons)

    elements.title = Roact.createElement(Title, {
        Title = props.Title,
    })

    elements.label = Roact.createElement(Label, {
        Text = props.Text,
        TextSize = 32,
    })

    elements.spinner = Roact.createElement()

    return Roact.createElement(DefaultFrame, {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size     = UDim2.new(0, 550, 0, 350),
    }, elements)
end
