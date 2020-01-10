local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local ToolTip = require(ui.common.ToolTip)

local InitiateControlButton = Roact.Component:extend("InitiateControlButton")

function InitiateControlButton:init()
    
end

function InitiateControlButton:render()
    return Roact.createElement("ImageButton", {
        Name                   = "InitiateControlButton",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 730, 1, -12),
        Size                   = UDim2.new(0,60,0,60),
        AnchorPoint            = Vector2.new(0, 1),
        Image                  = "rbxassetid://3480808137",
        [Roact.Event.MouseButton1Click] = self.props.UIBase.displayUnitControlSpots,
        [Roact.Event.MouseButton2Click] = self.props.UIBase.unmountUnitControlSpots,
    }, {
        tooltip = Roact.createElement(ToolTip, {
            Position = UDim2.new(0.5, 0, 0.5, -30),
            Text = "Control soldiers",
        })
    })
end

return InitiateControlButton