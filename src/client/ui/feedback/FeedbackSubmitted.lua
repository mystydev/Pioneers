local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local Title = require(ui.Title)
local Label = require(ui.Label)
local FeedbackSubmitted = Roact.Component:extend("FeedbackSubmitted")
local RunService = game:GetService("RunService")

function FeedbackSubmitted:init()
    self:setState({
        transparency = 1,
    })
end

function FeedbackSubmitted:render()

    local elements = {}

    elements.title = Roact.createElement(Title, {
        Title = "Feedback Submitted",
        TextTransparency = self.state.transparency + 0.1, 
        Position = UDim2.new(0.5, 0, 0.05, 15),
        Size = UDim2.new(1, 0, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
    })

    elements.description = Roact.createElement(Label, {
        Text = "Quality feedback helps improve Pioneers.\n\nThank you!",
        Position = UDim2.new(0.5, 0, 0.05, 70),
        Size = UDim2.new(1, 0, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
        TextSize = 20,
        TextTransparency = self.state.transparency + 0.1,
    })

    return Roact.createElement("ImageLabel", {
        Name                   = "FeedbackSubmitted",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 382, 0, 251),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3617570155",
        ImageTransparency      = self.state.transparency,
    }, elements)
end

function FeedbackSubmitted:didMount()
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

function FeedbackSubmitted:willUnmount()
    self.running = false
end

return FeedbackSubmitted