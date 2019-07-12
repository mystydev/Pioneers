local ui = script.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local Label = require(ui.Label)
local ObjectSelection = require(Client.ObjectSelection)
local Unit = require(Common.Unit)
local Resource = require(Common.Resource)

local UnitInfoLabel = Roact.Component:extend("UnitInfoLabel")

UnitInfoLabel.Interests = {}
UnitInfoLabel.Interests.CARRYING = 1
UnitInfoLabel.Interests.STATUS = 2

local StateDisplay = {}
StateDisplay[Unit.UnitState.IDLE] = "rbxassetid://3134625456"
StateDisplay[Unit.UnitState.DEAD] = "rbxassetid://3064453624"
StateDisplay[Unit.UnitState.MOVING] = "rbxassetid://3077211985"
StateDisplay[Unit.UnitState.WORKING] = "rbxassetid://3064453876"
StateDisplay[Unit.UnitState.RESTING] = "rbxassetid://3134628363"
StateDisplay[Unit.UnitState.STORING] = "rbxassetid://3064453818"
StateDisplay[Unit.UnitState.COMBAT] = "rbxassetid://3134625173"
StateDisplay[Unit.UnitState.LOST] = "rbxassetid://3134625520"

local CarryDisplay = {}
CarryDisplay["Food"] = "rbxassetid://3134625293"
CarryDisplay["Wood"] = "rbxassetid://3134628736"
CarryDisplay["Stone"] = "rbxassetid://3134633203"

function UnitInfoLabel:init(props)
    self:setState(props)
end

function UnitInfoLabel:render()

    local state = self.state.Unit.State and Unit.StateLocalisation[self.state.Unit.State] or "unknown"

    local displayImage
    local text

    if not self.state.IsUnit then

        displayImage = StateDisplay[self.state.Unit.State] or StateDisplay[Unit.UnitState.LOST]
        text = Unit.Localisation[self.state.Unit.Type] .. " - " .. state

    elseif self.state.Interest == UnitInfoLabel.Interests.CARRYING then

        local res = self.state.Unit.HeldResource

        if res and res.Amount > 0 then
            displayImage = CarryDisplay[res.Type] or StateDisplay[Unit.UnitState.LOST]
            text = "Carrying " .. (res.Amount or "?") .. " " .. res.Type
        else
            displayImage = ""
            text = ""
        end
    
    elseif self.state.Interest == UnitInfoLabel.Interests.STATUS then
        displayImage = StateDisplay[self.state.Unit.State] or StateDisplay[Unit.UnitState.LOST]
        text = state
    end

    return Roact.createElement("ImageButton", {
        Name = "UnitInfoLabel",
        BackgroundTransparency = 1,
        Position = self.state.Position or UDim2.new(0, 0, 0, 0),
        Size = self.state.Size or UDim2.new(0, 232, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = displayImage,
        [Roact.Event.MouseButton1Click] = function() self.props.SetObject(self.state.Unit) end
    }, {
        Label = Roact.createElement(Label, {Text = text})
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