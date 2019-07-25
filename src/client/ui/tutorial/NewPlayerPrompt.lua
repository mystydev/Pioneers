local ui    = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local NewPlayerPrompt = Roact.Component:extend("NewPlayerPrompt")

function NewPlayerPrompt:init()

end

function NewPlayerPrompt:render()
    
    local children = {}

    children.FollowTutorial = Roact.createElement("TextButton", {
        Text = "",
        Size = UDim2.new(0, 225, 0, 40),
        Position = UDim2.new(0.5, 0, 1, -17),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        [Roact.Event.MouseButton1Click] = self.props.UIBase.startTutorial,
    })

    children.SkipTutorial = Roact.createElement("TextButton", {
        Text = "",
        Size = UDim2.new(0, 225, 0, 40),
        Position = UDim2.new(0.5, 0, 1, -17),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        [Roact.Event.MouseButton1Click] = self.props.UIBase.dismissPrompt,
    })

    return Roact.createElement("ImageLabel", {
        Size                   = UDim2.new(0, 486, 0, 361),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://3465608887",
    }, children)
end

return NewPlayerPrompt
