local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local TweenService = game:GetService("TweenService")

local spin = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)

function LoadingSpinner(props)
    return Roact.createElement(ImageLabel, {
        Image    = "rbxassetid://3106304235"
        Position = UDim2.new(0.5, 0, 0.5, 0) or props.Position,
        Size     = UDim2.new(0, 200, 0, 200) or props.Size,
        
    }, elements)
end

return LoadingSpinner