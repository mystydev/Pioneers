local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local Label = require(ui.Label)
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local LoadingSpinner = Roact.Component:extend("LoadingSpinner")
local spin = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local quickfade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function LoadingSpinner:init()
    self:setState({
        ref = Roact.createRef(),
        vignetteRef = Roact.createRef(),
        textRef = Roact.createRef(),
    })
end

function LoadingSpinner:render()

    local message

    if self.props.message then
        message = Roact.createElement(Label, {
            Text = self.props.message,
            Color = Color3.fromRGB(230 , 230, 230),
            TextSize = 26,
            Position = UDim2.new(0.5, 0, 0.5, 120),
            Ref = self.state.textRef,
            TextTransparency = 1,
        })
    end

    local spinner = Roact.createElement("ImageLabel", {
        Image       = "rbxassetid://3106304235",
        Position    = UDim2.new(0.5, 0, 0.5, 0) or self.props.Position,
        Size        = UDim2.new(0, 200, 0, 200) or self.props.Size,
        AnchorPoint = Vector2.new(0.5, 0.5),
        [Roact.Ref] = self.state.ref,
        BackgroundTransparency = 1,
        ImageTransparency = 1,
        ImageColor3 = Color3.fromRGB(230 , 230, 230),
    })

    if self.props.vignette then
        return Roact.createElement("ImageLabel", {
            Image = "rbxassetid://3563730762",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ScaleType   = "Crop",
            ImageTransparency = 1,
            [Roact.Ref] = self.state.vignetteRef,
            ImageColor3 = Color3.new(0,0,0),
            BackgroundColor3 = Color3.fromRGB(33, 33, 33),
        }, {spinner, message})
    
    else
        return spinner
    end

end

function LoadingSpinner:didMount()
    local spinInst = self.state.ref:getValue()
    TweenService:Create(spinInst, spin, {Rotation = 360}):Play()
    TweenService:Create(spinInst, quickfade, {ImageTransparency = 0}):Play()

    local vigInst = self.state.vignetteRef:getValue()
    if vigInst then
        TweenService:Create(vigInst, fade, {ImageTransparency = 0, BackgroundTransparency = 0.7}):Play()
    end

    local textInst = self.state.textRef:getValue()
    if textInst then
        TweenService:Create(textInst, quickfade, {TextTransparency = 0}):Play()
    end

end

function LoadingSpinner:willUnmount()
    local spinInst = self.state.ref:getValue()
    TweenService:Create(spinInst, quickfade, {ImageTransparency = 1}):Play()

    local vigInst = self.state.vignetteRef:getValue()
    if vigInst then
        TweenService:Create(vigInst, fade, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
    end

    local textInst = self.state.textRef:getValue()
    if textInst then
        TweenService:Create(textInst, quickfade, {TextTransparency = 1}):Play()
    end
    wait(1)
end

return LoadingSpinner