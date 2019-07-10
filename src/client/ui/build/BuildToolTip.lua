local ui           = script.Parent.Parent
local Roact        = require(game.ReplicatedStorage.Roact)
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Common       = game.ReplicatedStorage.Pioneers.Common

local Tile          = require(Common.Tile)
local Title         = require(ui.Title)
local SmallResourceLabel = require(ui.common.SmallResourceLabel)

local BuildToolTip  = Roact.Component:extend("BuildToolTip")
local CostBinding, CostUpdate = Roact.createBinding(nil)

function BuildToolTip:init()
    self:setState({
        DisplayPosition = self.props.Position:getValue(),
        Transparency = self.props.Showing:getValue(),
        Type = self.props.Type:getValue(),
    })
end

function BuildToolTip:render()

    local children = {}

    children.Title = Roact.createElement(Title, {
        Title = Tile.Localisation[self.state.Type],
        TextTransparency = self.state.Transparency + 0.1, 
        Position = UDim2.new(0.5, 0, 0.05, 0),
        Size = UDim2.new(0, 326, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
    })

    children.Description = Roact.createElement("TextLabel", {
        Name                   = "Description",
        Text                   = Tile.Description[self.state.Type],
        TextTransparency       = self.state.Transparency + 0.1,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0.2, 0),
        Size                   = UDim2.new(0, 250, 0, 32),
        Font                   = "SourceSans",
        TextSize               = 16,
        TextWrap               = true,
        TextColor3             = Color3.fromRGB(61,61,61),
        TextXAlignment         = "Center",
        AnchorPoint            = Vector2.new(0.5, 0),
    })

    children.CostTitle = Roact.createElement(Title, {
        Title = "Cost",
        TextSize = 28,
        TextTransparency = self.state.Transparency + 0.1, 
        Position = UDim2.new(0.5, 0, 0.6, 0),
        Size = UDim2.new(0, 250, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
    })

    children.WoodCost = Roact.createElement(SmallResourceLabel, {
        Type = "Wood",
        Position = UDim2.new(0.3, 0, 0.7, 5),
        Value = CostBinding,
        Transparency = self.state.Transparency + 0.1,
    })

    children.StoneCost = Roact.createElement(SmallResourceLabel, {
        Type = "Stone",
        Position = UDim2.new(0.6, 0, 0.7, 5),
        Value = CostBinding,
        Transparency = self.state.Transparency + 0.1,
    })

    return Roact.createElement("ImageLabel", {
        Name                   = "BuildToolTip",
        BackgroundTransparency = 1,
        Position               = self.state.DisplayPosition + UDim2.new(0, 25, 0, -30),
        Size                   = UDim2.new(0, 326, 0, 304),
        AnchorPoint            = Vector2.new(0.5, 1),
        Image                  = "rbxassetid://3437122618",
        ImageTransparency      = self.state.Transparency,
    }, children)
end

function BuildToolTip:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                local delta = state.DisplayPosition - self.props.Position:getValue()
                local alpha = 0.15

                if math.abs(delta.X.Offset) < 20 then
                    alpha = 1 / math.clamp(math.abs(delta.X.Offset), 2, 3)
                end
                
                CostUpdate(Tile.ConstructionCosts[self.props.Type:getValue()])

                return {
                    DisplayPosition = state.DisplayPosition:Lerp(self.props.Position:getValue(), alpha),
                    Transparency = state.Transparency + math.clamp((self.props.Showing:getValue() - state.Transparency) * 0.2, -0.05, 0.05),
                    Type = self.props.Type:getValue(),
                }
            end)

            RunService.Heartbeat:Wait()
        end
    end)
end

function BuildToolTip:willUnmount()
    self.running = false
end

return BuildToolTip