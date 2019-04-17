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

local largeSize = UDim2.new(0, 137, 0, 43)

function ResourceLabel:init(props)
    self:setState(props)
end

function ResourceLabel:render()

    local displayValue = math.floor((self.state.display or 0) + 0.5)

    return Roact.createElement("ImageLabel", {
        Name                   = "ResLabel",
        BackgroundTransparency = 1,
        Position               = self.state.Position,
        Size                   = largeSize,
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        Image                  = largeIds[self.state.Type],
        ImageTransparency      = 0.3,
        AnchorPoint            = Vector2.new(0, 1)
        }, {
            Label = Roact.createElement(Label, {
                            Text = displayValue, 
                            TextSize = 26, 
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