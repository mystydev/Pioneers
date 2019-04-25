local ui = script.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local Label = require(ui.Label)
local ObjectSelection = require(Client.ObjectSelection)
local Unit = require(Common.Unit)

local UnitInfoLabel = Roact.Component:extend("UnitInfoLabel")

local StateDisplay = {}
StateDisplay[Unit.UnitState.IDLE] = "rbxassetid://3064453624"
StateDisplay[Unit.UnitState.DEAD] = "rbxassetid://3064453624"
StateDisplay[Unit.UnitState.MOVING] = "rbxassetid://3077211985"
StateDisplay[Unit.UnitState.WORKING] = "rbxassetid://3064453876"
StateDisplay[Unit.UnitState.RESTING] = "rbxassetid://3064453760"
StateDisplay[Unit.UnitState.STORING] = "rbxassetid://3064453818"

function UnitInfoLabel:init(props)
    self:setState(props)
end

function UnitInfoLabel:render()

    local state = self.state.Unit.State and Unit.StateLocalisation[self.state.Unit.State] or "unknown"

    return Roact.createElement("ImageButton", {
        Name = "UnitInfoLabel",
        BackgroundTransparency = 1,
        Position = self.state.Position or UDim2.new(0, 0, 0, 0),
        Size = self.state.Size or UDim2.new(0, 232, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = StateDisplay[self.state.Unit.State],
        [Roact.Event.MouseButton1Click] = function() ObjectSelection.select(self.state.Unit) end
    }, {
        Label = Roact.createElement(Label, {Text = Unit.Localisation[self.state.Unit.Type] .. " - " .. state})
    })
end

function UnitInfoLabel:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(self.state)
            wait(0.1)
        end
    end)
end

function UnitInfoLabel.getDerivedStateFromProps(nextProps, lastState)
    return nextProps
end

function UnitInfoLabel:willUnmount()
    self.running = false
end

return UnitInfoLabel