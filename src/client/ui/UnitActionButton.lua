local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local ActionList = require(ui.ActionList)

local UnitActionButton = Roact.Component:extend("UnitActionButton")

function UnitActionButton:init(props)
    self:setState(props)
end

function UnitActionButton:render()
    return Roact.createElement("ImageButton", {
        Name                   = "UnitActionButton",
        BackgroundTransparency = 1,
        Position               = self.state.Position,
        Size                   = UDim2.new(0,64,0,64),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3077218297",
        HoverImage             = "rbxassetid://3077212059",
        PressedImage           = "rbxassetid://3077212059",
        [Roact.Event.MouseButton1Click] = function() self:setState({actionList = ActionList}) end,
    }, self.state.actionList)
end

return UnitActionButton