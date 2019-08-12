
local Roact = require(game.ReplicatedStorage.Roact)
local TweenService = game:GetService("TweenService")

local UpdateAlert = Roact.Component:extend("UpdateAlert")
local fade = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function UpdateAlert:init()
    self.updateRef = Roact.createRef()
    self:setState({
        updating = true,
    })
end

function UpdateAlert:render()
    return Roact.createElement("ImageLabel", {
        Name                   = "UpdateAlert",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 20, 0, -50),
        Size                   = UDim2.new(0, 343, 0, 217),
        AnchorPoint            = Vector2.new(0, 0),
        Image                  = self.state.updating and "rbxassetid://3606598190" or "rbxassetid://3606598062",
        [Roact.Ref]            = self.updateRef,
    })
end

function UpdateAlert:didMount()
    TweenService:Create(self.updateRef.current, fade, {Position = UDim2.new(0, 20, 0, 35)}):Play()

    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                return {
                    updating = self.props.updating:getValue()
                }
            end)
            wait(0.5)
        end
    end)
end

function UpdateAlert:willUnmount()
    self.running = false
end

return UpdateAlert