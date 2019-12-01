local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local Label = require(ui.Label)
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local LoadingSpinner = Roact.Component:extend("LoadingSpinner")
local spin = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local quickfade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local hexagonPositions = {
    Vector2.new(0, 0),

    Vector2.new(0, 1),
    Vector2.new(-0.866, 0.5),
    Vector2.new(-0.866, -0.5),
    Vector2.new(0, -1),
    Vector2.new(0.866, -0.5),
    Vector2.new(0.866, 0.5),

    Vector2.new(0.866, 1.5),
    Vector2.new(0, 2),
    Vector2.new(-0.866, 1.5),
    Vector2.new(2 * -0.866, 1.0),
    Vector2.new(2 * -0.866, 0),
    Vector2.new(2 * -0.866, -1.0),
    Vector2.new(-0.866, -1.5),
    Vector2.new(0, -2),
    Vector2.new(0.866, -1.5),
    Vector2.new(2 * 0.866, -1.0),
    Vector2.new(2 * 0.866, 0),
    Vector2.new(2 * 0.866, 1.0),
}

local scale = 0.33
local speed = 1
local spread = 1
local interval = 0.3

function LoadingSpinner:init()
    self:setState({
        time = 0,
        frameRef = Roact.createRef(),
        vignetteRef = Roact.createRef(),
        textRef = Roact.createRef(),
    })
end

function LoadingSpinner:render()
    local hexagons = {}
    local num = #hexagonPositions

    for i, position in pairs(hexagonPositions) do
        local posCombination = position.x + position.y
        
        hexagons[i] = Roact.createElement("ImageLabel",{
            Image = "rbxassetid://4431055230",
            Size = UDim2.new(0, 100 * scale, 0, 86 * scale),
            Position = UDim2.new(0, position.x * 100 * scale, 0, position.y * -100 * scale),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            ImageTransparency = 0.4 - math.sin(2 * math.pi * ((interval * num * self.state.time + (num-i)^0.5) % num/(num))),
            ImageColor3 = Color3.fromHSV(
                (0.2*tick() + posCombination*0.03)%1, 
                1.0, 
                1.0),
        })
    
    end

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

    local rot = math.tan(interval * math.pi * self.state.time * 0.5 + 2.1)
    local sign = math.sign(rot)

    local spinner = Roact.createElement("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, -30),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Rotation = 360 * 0.3 * sign * math.log(math.abs(rot)),
        [Roact.Ref] = self.state.frameRef,
    }, hexagons)

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
    self:setState({
        time = -1.2,
        updater = RunService.Stepped:Connect(function(time, delta)            
            self:setState({
                time = self.state.time + delta,
            })
        end)
    })

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

    self.state.updater:Disconnect()

    for _, hexagon in pairs(self.state.frameRef:getValue():GetChildren()) do
        TweenService:Create(hexagon, fade, {ImageTransparency = 1}):Play()
    end

    local vigInst = self.state.vignetteRef:getValue()
    if vigInst then
        TweenService:Create(vigInst, fade, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
    end

    local textInst = self.state.textRef:getValue()
    if textInst then
        TweenService:Create(textInst, quickfade, {TextTransparency = 1}):Play()
    end

    wait(0.6)
end

return LoadingSpinner