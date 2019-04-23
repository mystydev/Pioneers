local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local Label = require(ui.Label)

local RunService = game:GetService("RunService")

local ResourceLabel = Roact.Component:extend("ResourceLabel")

local largeIds = {
    Food = "rbxassetid://3063644663",
    Wood = "rbxassetid://3063644615",
    Stone = "rbxassetid://3063644706"
}

local smallIds = {
    Food = "rbxassetid://3064039406",
    Wood = "rbxassetid://3064039535",
    Stone = "rbxassetid://3064039482"
}

local largeSize = UDim2.new(0, 137, 0, 43)
local smallSize = UDim2.new(0, 82, 0, 32)

function ResourceLabel:init(props)
    self:setState(props)
end

function ResourceLabel:render()

    local displayValue = math.floor((self.state.display or 0) + 0.5)
    local size = self.state.Small and smallSize or largeSize
    local id = self.state.Small and smallIds[self.state.Type] or largeIds[self.state.Type]
    local textSize = self.state.Small and 18 or 26

    return Roact.createElement("ImageLabel", {
        Name                   = "ResLabel",
        BackgroundTransparency = 1,
        Position               = self.state.Position,
        Size                   = size,
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        Image                  = id,
        ImageTransparency      = 0.3,
        AnchorPoint            = Vector2.new(0, 1)
        }, {
            Label = Roact.createElement(Label, {
                            Text = displayValue, 
                            TextSize = textSize, 
                            Position = UDim2.new(0, 10, 0, -2)})
        })
end

function ResourceLabel:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                local cval = state.display or 0
                local tval = self.state.stats[self.state.Type]

                return {
                    display = cval + (tval - cval)*0.1
                }
                
            end)
            RunService.Stepped:Wait()
        end
    end)
end

function ResourceLabel:willUnmount()
    self.running = false
end

return ResourceLabel