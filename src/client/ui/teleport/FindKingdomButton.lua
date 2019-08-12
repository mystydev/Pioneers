local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local FindKingdomButton = Roact.Component:extend("FindKingdomButton")

function FindKingdomButton:init()
    
end

function FindKingdomButton:render()
    return Roact.createElement("ImageButton", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 120, 0, -15),
        Size                   = UDim2.new(0,63,0,63),
        Image                  = "rbxassetid://3623902014",
        [Roact.Event.MouseButton1Click] = self.props.UIBase.showFindKingdom,
        [Roact.Event.MouseButton2Click] = self.props.UIBase.exitFindKingdomView,
    })
end

return FindKingdomButton