local ui = script.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local UnitInfoLabel = require(ui.UnitInfoLabel)
local Label = require(ui.Label)
local Tile = require(Common.Tile)
local ObjectSelection = require(Client.ObjectSelection)

local TweenService = game:GetService("TweenService")

local ActionListButton = Roact.Component:extend("ActionListButton")
local uitween = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local Actions = {}
Actions.SetWork = 1

local ActionLocalisation = {}
ActionLocalisation[Actions.SetWork] = "Set Work"

function ActionListButton:init(props)
    self:setState(props)
    self.instRef = Roact.createRef()
end

function ActionListButton:render()

    return Roact.createElement("ImageButton", {
        Name = "ActionListButton",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 82, 0, 48),
        Image = "rbxassetid://3064022555",
        HoverImage = "rbxassetid://3064056895",
        PressedImage = "rbxassetid://3064056895",
        Position = self.Position or UDim2.new(0,0,0,0),
        [Roact.Ref] = self.instRef,
        [Roact.Event.MouseButton1Click] = ObjectSelection.assignWorkPrompt,
    }, {
        Label = Roact.createElement(Label, {
            Text = ActionLocalisation[self.state.Type],
        })
    })
end

function ActionListButton:didMount()
    TweenService:Create(self.instRef.current, uitween, {Position = UDim2.new(0, -10, 0, -48 * self.state.Type -12)}):Play()
    self.Position = UDim2.new(0, -10, 0, -48 * self.state.Type -12)
end

local buttons = {}

for i, v in pairs(Actions) do 
    table.insert(buttons, Roact.createElement(ActionListButton, {Type = v}))
end

return buttons