local ui     = script.Parent.Parent
local Client = ui.Parent

local ActionHandler = require(Client.ActionHandler)
local Title         = require(ui.Title)
local Label         = require(ui.Label)
local CloseButton   = require(ui.CloseButton)
local Roact         = require(game.ReplicatedStorage.Roact)
local RunService    = game:GetService("RunService")

local FeedbackForm = Roact.Component:extend("FeedbackForm")

function FeedbackForm:submitted(react, text)
    ActionHandler.sendFeedback(react, text)
    self.props.UIBase.submittedFeedback()
end

function FeedbackForm:init()
    self:setState({
        transparency = 1,
    })
end 

function FeedbackForm:render()

    local elements = {}

    elements.title = Roact.createElement(Title, {
        Title = "Feedback",
        TextTransparency = self.state.transparency + 0.1, 
        Position = UDim2.new(0.5, 0, 0.05, 0),
        Size = UDim2.new(1, 0, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
    })

    elements.description = Roact.createElement(Label, {
        Text = "Use this form to submit feedback to the development team directly. \nPlease keep feedback short and to the point.",
        TextTransparency = self.state.transparency + 0.1,
        Position = UDim2.new(0.5, 0, 0.05, 50),
        Size = UDim2.new(1, 0, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
        TextSize = 20,
    })

    elements.happyButton = Roact.createElement("ImageButton", {
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(1, -35, 1, -10),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = self.state.transparency + 0.3,
        Image = "rbxassetid://3617566131",
        [Roact.Event.MouseEnter] = function(this) this.ImageTransparency = 0 end,
        [Roact.Event.MouseLeave] = function(this) this.ImageTransparency = 0.3 end,
        [Roact.Event.MouseButton1Click] = function(button) self:submitted("Happy", button.Parent.textBox.Text) end,
    })

    elements.confusedButton = Roact.createElement("ImageButton", {
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(1, -88, 1, -10),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = self.state.transparency + 0.3,
        Image = "rbxassetid://3617566041",
        [Roact.Event.MouseEnter] = function(this) this.ImageTransparency = 0 end,
        [Roact.Event.MouseLeave] = function(this) this.ImageTransparency = 0.3 end,
        [Roact.Event.MouseButton1Click] = function(button) self:submitted("Confused", button.Parent.textBox.Text) end,
    })

    elements.unhappyButton = Roact.createElement("ImageButton", {
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(1, -141, 1, -10),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = self.state.transparency + 0.3,
        Image = "rbxassetid://3617566224",
        [Roact.Event.MouseEnter] = function(this) this.ImageTransparency = 0 end,
        [Roact.Event.MouseLeave] = function(this) this.ImageTransparency = 0.3 end,
        [Roact.Event.MouseButton1Click] = function(button) self:submitted("Unhappy", button.Parent.textBox.Text) end,
    })

    elements.angryButton = Roact.createElement("ImageButton", {
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(1, -194, 1, -10),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        ImageTransparency = self.state.transparency + 0.3,
        Image = "rbxassetid://3617565951",
        [Roact.Event.MouseEnter] = function(this) this.ImageTransparency = 0 end,
        [Roact.Event.MouseLeave] = function(this) this.ImageTransparency = 0.3 end,
        [Roact.Event.MouseButton1Click] = function(button) self:submitted("Angry", button.Parent.textBox.Text) end,
    })

    elements.closeButton = Roact.createElement(CloseButton, {
        Position = UDim2.new(0, 20, 1, -20),
        AnchorPoint = Vector2.new(0, 1),
        OnClick = self.props.UIBase.exitFeedbackView,
        TextTransparency = self.state.transparency,
    })

    elements.textBox = Roact.createElement("TextBox", {
        PlaceholderText = "...",
        Text = "",
        TextColor3 = Color3.fromRGB(61,61,61),
        TextTransparency = self.state.transparency,
        Size = UDim2.new(0, 460, 0, 300),
        Position = UDim2.new(0.5, 0, 0.5, 55),
        AnchorPoint = Vector2.new(0.5, 0.5),
        TextSize = "22",
        Font = "SourceSans",
        BackgroundTransparency = 1,
        TextXAlignment = "Left",
        TextYAlignment = "Top",
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = true,
    })

    return Roact.createElement("ImageLabel", {
        Name                   = "FeedbackForm",
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 583, 0, 521),
        BackgroundTransparency = 1,
        ImageTransparency      = self.state.transparency,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3617566332",
    }, elements)
end

function FeedbackForm:didMount()
    self.running = true

    spawn(function()
        local dt = 0.016

        while self.running and self.state.transparency > 0 do

            self:setState(function(state)
                return {
                    transparency = state.transparency - dt * 8
                }
            end)

            dt = RunService.Heartbeat:Wait()
        end
    end)
end

function FeedbackForm:willUnmount()
    self.running = false
end

return FeedbackForm
