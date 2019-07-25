local ui    = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local NextPromptButton = Roact.Component:extend("NextPromptButton")

function NextPromptButton:init()

end

function NextPromptButton:render()
    
    local children = {}

    return Roact.createElement("ImageButton", {
        Size                   = UDim2.new(0, 51, 0, 51),
        Position               = UDim2.new(0.5, 260, 0, 25),
        AnchorPoint            = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://3470354088",
        [Roact.Event.MouseButton1Click] = self.props.onClick,
    }, children)
end

return NextPromptButton
