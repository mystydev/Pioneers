local Roact = require(game.ReplicatedStorage.Roact)

local TweenService  = game:GetService("TweenService")
local DefaultFrame = Roact.Component:extend("DefaultFrame")

local quickfade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function DefaultFrame:init()
    self:setState({
        ref = Roact.createRef()
    })
end

function DefaultFrame:render()
    return Roact.createElement("ImageLabel", {
        BackgroundTransparency = 1,
        Position               = self.props.Position or UDim2.new(0, 0, 0, 0),
        Size                   = self.props.Size or UDim2.new(1, 0, 1, 0),
        AnchorPoint            = self.props.AnchorPoint or Vector2.new(0.5, 0.5),
        ImageColor3            = self.props.ImageColor3 or Color3.new(1,1,1),
        ImageTransparency      = 1,
        ScaleType              = "Slice",
        SliceCenter            = Rect.new(30, 30, 50, 50),
        Image                  = "rbxassetid://4123559260",
        ZIndex                 = self.props.ZIndex,
        [Roact.Ref]            = self.state.ref,
    }, self.props[Roact.Children])
end

local function fadeChildrenIn(instance)
    for i, v in pairs(instance:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            local transparency = v.TextTransparency
            v.TextTransparency = 1
            TweenService:Create(v, quickfade, {TextTransparency = transparency}):Play()
        elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then
            local transparency = v.ImageTransparency
            v.ImageTransparency = 1
            TweenService:Create(v, quickfade, {ImageTransparency = transparency}):Play()
        end
    end
end

local function fadeChildrenOut(instance)
    for i, v in pairs(instance:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            TweenService:Create(v, quickfade, {TextTransparency = 1}):Play()
        elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then
            TweenService:Create(v, quickfade, {ImageTransparency = 1}):Play()
        end
    end
end

function DefaultFrame:didMount()
    local inst = self.state.ref:getValue()
    TweenService:Create(inst, quickfade, {ImageTransparency = self.props.ImageTransparency or 0.2}):Play()
    fadeChildrenIn(inst)
end

function DefaultFrame:willUnmount()
    local inst = self.state.ref:getValue()
    TweenService:Create(inst, quickfade, {ImageTransparency = 1}):Play()
    fadeChildrenOut(inst)
    wait(0.2)
end

return DefaultFrame