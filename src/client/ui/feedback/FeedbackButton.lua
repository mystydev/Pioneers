local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local FeedbackButton = Roact.Component:extend("FeedbackButton")

function FeedbackButton:init()
    
end

function FeedbackButton:render()
    return Roact.createElement("ImageButton", {
        Name                   = "FeedbackButton",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 50, 0, 0),
        Size                   = UDim2.new(0,72,0,36),
        Image                  = "rbxassetid://3617157264",
        [Roact.Event.MouseButton1Click] = self.props.UIBase.showFeedbackForm,
        [Roact.Event.MouseButton2Click] = self.props.UIBase.exitFeedbackView,
    })
end

return FeedbackButton