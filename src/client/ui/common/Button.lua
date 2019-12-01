local Client = script.Parent.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local SoundManager = require(Client.SoundManager)

local TextService = game:GetService("TextService")

local Button = Roact.Component:extend("Button")

function Button:init()
    self:setState({
        hoverStatus = 0,
    })
end

function Button:render()

    local textSize = TextService:GetTextSize(self.props.Text or "?", 16, "Legacy", Vector2.new(0,0))
    local buttonWidth

    if textSize.x > 80 then
        buttonWidth = textSize.x + 50
    else
        buttonWidth = 130
    end

    label = Roact.createElement("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(1, 0, 1, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        TextColor3             = (self.state.hoverStatus == 0) and (self.props.Color or Color3.fromRGB(33, 33, 33)) or Color3.fromRGB(230 , 230, 230),
        Text                   = self.props.Text or "?",
        TextSize               = 16
    })

    return Roact.createElement("ImageButton", {
        BackgroundTransparency = 1,
        Position                 = self.props.Position or UDim2.new(0.5, 0, 0.8, 0),
        Size                     = self.props.Size or UDim2.new(0, buttonWidth, 0, 48),
        AnchorPoint              = self.props.AnchorPoint or Vector2.new(0.5, 0.5),
        ImageColor3              = self.props.Color or Color3.fromRGB(33, 33, 33),
        ImageTransparency        = self.props.ImageTransparency or 0,
        ScaleType                = "Slice",
        SliceCenter              = Rect.new(15, 33, 15, 33),
        [Roact.Event.MouseEnter] = function() SoundManager.rollover() self:setState({hoverStatus = 1}) end,
        [Roact.Event.MouseLeave] = function() self:setState({hoverStatus = 0}) end,
        [Roact.Event.MouseButton1Click] = function() SoundManager.menuClick() self.props.ClickEvent() end,
        Image                    = (self.state.hoverStatus == 0) and "rbxassetid://4312670626" or "rbxassetid://4298535124",
    }, label)
end

return Button