
local Roact = require(game.ReplicatedStorage.Roact)
local TweenService = game:GetService("TweenService")

local CombatWarning = Roact.Component:extend("CombatWanrning")
local fade = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function CombatWarning:init()
    self.warningRef = Roact.createRef()
end

function CombatWarning:render()
    return Roact.createElement("ImageLabel", {
        Name                   = "CombatWarning",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0, -50),
        Size                   = UDim2.new(0, 273, 0, 89),
        AnchorPoint            = Vector2.new(0.5, 0),
        Image                  = "rbxassetid://3606598274",
        [Roact.Ref]            = self.warningRef,
    })
end

function CombatWarning:didMount()
    TweenService:Create(self.warningRef.current, fade, {Position = UDim2.new(0.5, 0, 0, 20)}):Play()
end

return CombatWarning