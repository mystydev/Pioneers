local ui    = script.Parent.Parent
local Client = ui.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local SoundManager = require(Client.SoundManager)
local PreviousPromptButton = Roact.Component:extend("PreviousPromptButton")

function PreviousPromptButton:init()

end

function PreviousPromptButton:render()
    
    local children = {}

    return Roact.createElement("ImageButton", {
        Size                   = UDim2.new(0, 51, 0, 51),
        Position               = UDim2.new(0.5, -260, 0, 25),
        AnchorPoint            = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://3470770300",
        [Roact.Event.MouseButton1Click] = self.props.onClick,
        [Roact.Event.MouseEnter] = SoundManager.highlight,
    }, children)
end

return PreviousPromptButton
