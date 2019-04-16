local ui = script.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local UnitInfoLabel = require(ui.UnitInfoLabel)
local Label = require(ui.Label)
local Tile = require(Common.Tile)
local ObjectSelection = require(Client.ObjectSelection)

local TweenService = game:GetService("TweenService")

local BuildListButton = Roact.Component:extend("BuildListButton")
local uitween = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)


function BuildListButton:init(props)
    self:setState(props)
    self.instRef = Roact.createRef()
end

function BuildListButton:render()

    return Roact.createElement("ImageButton", {
        Name = "BuildListButton",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 82, 0, 48),
        Image = "rbxassetid://3064022555",
        HoverImage = "rbxassetid://3064056895",
        PressedImage = "rbxassetid://3064056895",
        Position = self.Position or UDim2.new(0,0,0,0),
        [Roact.Ref] = self.instRef,
        [Roact.Event.MouseButton1Click] = function() ObjectSelection.buildTileAtSelection(self.state.Type) end,
    }, {
        Label = Roact.createElement(Label, {
            Text = Tile.Localisation[self.state.Type],
        })
    })
end

function BuildListButton:didMount()
    TweenService:Create(self.instRef.current, uitween, {Position = UDim2.new(0, -10, 0, -48 * self.state.Type -12)}):Play()
    self.Position = UDim2.new(0, -10, 0, -48 * self.state.Type -12)
end

local buttons = {}

for i = 1, Tile.NumberTypes do 
    table.insert(buttons, Roact.createElement(BuildListButton, {Type = i}))
end

return buttons