local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local Label = require(ui.Label)
local RunService = game:GetService("RunService")

local SmallResourceLabel = Roact.Component:extend("ResourceLabel")

local imageIds = {
    Food = "rbxassetid://3064039406",
    Wood = "rbxassetid://3064039535",
    Stone = "rbxassetid://3064039482"
}

function SmallResourceLabel:init()
    self:setState({
        Value = 0,
    })
end

function SmallResourceLabel:render()

    local children = {}

    children.Label = Roact.createElement(Label, {
        Text = self.state.Value, 
        TextSize = 18,
        Position = UDim2.new(0, 10, 0, -2),
        Size = UDim2.new(1, 0, 1, 0),
        TextTransparency = self.props.Transparency,
        TextXAlignment = "Left",
        AnchorPoint = Vector2.new(0, 0),
    })

    return Roact.createElement("ImageLabel", {
        Name                   = "SmallResLabel",
        BackgroundTransparency = 1,
        Position               = self.props.Position,
        Size                   = UDim2.new(0, 82, 0, 32),
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        Image                  = imageIds[self.props.Type],
        ImageTransparency      = self.props.Transparency or 0,
        AnchorPoint            = Vector2.new(0, 1),
    }, children)
end

function SmallResourceLabel:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                local val = self.props.Value:getValue()

                if val then
                    local delta = (val[self.props.Type] - self.state.Value)*0.1

                    if delta == 0 then
                        return
                    end
                    
                    if (delta > 0) then
                        delta = math.floor(math.max(delta, 1) + 0.5)
                    else
                        delta = math.floor(math.min(delta, -1) - 0.5)
                    end

                    return {
                        Value = self.state.Value + delta
                    }
                end
            end)

            RunService.Heartbeat:Wait()
        end
    end)
end

function SmallResourceLabel:willUnmount()
    self.running = false
end

return SmallResourceLabel