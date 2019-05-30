local Roact = require(game.ReplicatedStorage.Roact)
local TweenService = game:GetService("TweenService")

local empty = "rbxassetid://3137132874"
local filled = "rbxassetid://3137569139"
local check  = "rbxassetid://3137132820"

local CheckBox = Roact.Component:extend("CheckBox")

local checkInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local fadeInfo2 = TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true)
local fadeTime = 0.1

function CheckBox:onClick()
    self:setState({lastClick = tick(), Checked = not self.state.Checked})

    if self.state.Checked then
        self.checkRef.current.Size = UDim2.new(0,0,0,13)
        self.backRef.current.Size = UDim2.new(0,0,0,0)
        TweenService:Create(self.checkRef.current, checkInfo, {Size = UDim2.new(0,17,0,13)}):Play()
        self.backRef.current.ImageTransparency = 1
        TweenService:Create(self.backRef.current, fadeInfo, {Size = UDim2.new(0,40,0,40)}):Play()
        TweenService:Create(self.backRef.current, fadeInfo2, {ImageTransparency = 0.8}):Play()
    else
        self.checkRef.current.Size = UDim2.new(0,17,0,13)
        self.backRef.current.Size = UDim2.new(0,0,0,0)
        TweenService:Create(self.checkRef.current, checkInfo, {Size = UDim2.new(0,0,0,13)}):Play()
        self.backRef.current.ImageTransparency = 1
        TweenService:Create(self.backRef.current, fadeInfo, {Size = UDim2.new(0,40,0,40)}):Play()
        TweenService:Create(self.backRef.current, fadeInfo2, {ImageTransparency = 0.8}):Play()
    end

    if self.state.Clicked then
        self.state.Clicked(self.state.Checked)
    end
end

function CheckBox:init(props)
    if not props.Checked then props.Checked = false end
    self:setState(props)

    self.checkRef = Roact.createRef()
    self.backRef = Roact.createRef()
end

function CheckBox:render()
    
    local state = self.state
    local elements = {}

    elements.Check = Roact.createElement("ImageLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5,0,0.5,0),
        Size                   = state.Checked and UDim2.new(0,17,0,13) or UDim2.new(0,0,0,0),
        Image                  = check,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        ImageColor3            = Color3.new(0,0,0),
        ImageTransparency      = 0.4,
        ScaleType              = "Crop",
        [Roact.Ref]            = self.checkRef,
    })

    elements.Hover = Roact.createElement("ImageLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5,0,0.5,0),
        Size                   = state.Hovering and UDim2.new(0,40,0,40) or UDim2.new(0,0,0,0),
        Image                  = filled,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        ImageColor3            = Color3.new(0,0,0),
        ImageTransparency      = 0.97,
    })

    elements.Back = Roact.createElement("ImageLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5,0,0.5,0),
        Size                   = UDim2.new(0,0,0,0),
        Image                  = filled,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        ImageColor3            = Color3.new(0,0,0),
        ImageTransparency      = 0.6,
        [Roact.Ref]            = self.backRef,
    })

    return Roact.createElement("ImageButton", {
        Name                   = "CheckBox",
        BackgroundTransparency = 1,
        Position               = state.Position,
        Size                   = UDim2.new(0,23,0,23),
        Image                  = empty,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        ImageColor3            = Color3.new(0,0,0),
        ImageTransparency      = 0.4,
        ScaleType              = "Fit",
        [Roact.Event.MouseButton1Click] = function() self:onClick() end,
        [Roact.Event.MouseEnter] = function() self:setState{Hovering = true} end,
        [Roact.Event.MouseLeave] = function() self:setState{Hovering = false} end,
    }, elements)
end

return CheckBox