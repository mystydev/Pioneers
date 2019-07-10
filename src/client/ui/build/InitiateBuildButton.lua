local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local InitiateBuildButton = Roact.Component:extend("InitiateBuildButton")

function InitiateBuildButton:init()
    
end

function InitiateBuildButton:render()
    return Roact.createElement("ImageButton", {
        Name                   = "InitiateBuildButton",
        BackgroundTransparency = 1,
        Position               = self.props.Position,
        Size                   = UDim2.new(0,50,0,50),
        AnchorPoint            = Vector2.new(0, 1),
        Image                  = "rbxassetid://3437143987",
        [Roact.Event.MouseButton1Click] = self.props.UIBase.showBuildList,
        [Roact.Event.MouseButton2Click] = self.props.UIBase.hideBuildList,
    })
end

return InitiateBuildButton