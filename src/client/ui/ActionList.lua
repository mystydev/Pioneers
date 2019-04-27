local ui = script.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local UnitInfoLabel = require(ui.UnitInfoLabel)
local Label = require(ui.Label)
local Tile = require(Common.Tile)
local World = require(Common.World)
local ObjectSelection = require(Client.ObjectSelection)
local SoundManager    = require(Client.SoundManager)

local TweenService = game:GetService("TweenService")

local ActionListButton = Roact.Component:extend("ActionListButton")
local uitween = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

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
        [Roact.Event.MouseButton1Click] = function() ObjectSelection.assignTilePrompt(self.state.Type) end,
        [Roact.Event.MouseEnter] = SoundManager.highlight,
    }, {
        Label = Roact.createElement(Label, {
            Text = World.ActionLocalisation[self.state.Type],
        })
    })
end

function ActionListButton:didMount()
    TweenService:Create(self.instRef.current, uitween, {Position = UDim2.new(0, -10, 0, -48 * self.state.index -12)}):Play()
    self.Position = UDim2.new(0, -10, 0, -48 * self.state.index -12)
end

local buttons = {}

for index, action in pairs(World.UnitActions) do 
    table.insert(buttons, Roact.createElement(ActionListButton, {Type = action, index = index}))
end

return buttons