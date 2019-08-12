local ui     = script.Parent.Parent
local Client = ui.Parent

local ActionHandler = require(Client.ActionHandler)
local Title         = require(ui.Title)
local Label         = require(ui.Label)
local CloseButton   = require(ui.CloseButton)
local DefaultFrame  = require(ui.common.DefaultFrame)
local Roact         = require(game.ReplicatedStorage.Roact)
local RunService    = game:GetService("RunService")

local FindKingdom = Roact.Component:extend("FindKingdom")

function FindKingdom:submitted(react, text)
    ActionHandler.sendFeedback(react, text)
    self.props.UIBase.submittedFeedback()
end

function FindKingdom:init()
    self:setState({
        transparency = 1,
    })
end 

function FindKingdom:render()

    local elements = {}

    elements.title = Roact.createElement(Title, {
        Title = "Find Kingdom",
        TextTransparency = self.state.transparency + 0.1, 
        Position = UDim2.new(0.5, 0, 0.05, 0),
        Size = UDim2.new(1, 0, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
    })

    elements.description = Roact.createElement(Label, {
        Text = "Want to visit another kingdom?\nEnter the owner's username below to search.",
        TextTransparency = self.state.transparency + 0.1,
        Position = UDim2.new(0.5, 0, 0.05, 50),
        Size = UDim2.new(1, 0, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
        TextSize = 20,
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

    return Roact.createElement(DefaultFrame, {
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 583, 0, 521),
        --ImageTransparency      = self.state.transparency,
        AnchorPoint            = Vector2.new(0.5, 0.5),
    }, elements)
end

function FindKingdom:didMount()
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

function FindKingdom:willUnmount()
    self.running = false
end

return FindKingdom
