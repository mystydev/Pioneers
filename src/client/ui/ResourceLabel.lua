local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local Label = require(ui.Label)

local RunService = game:GetService("RunService")

local ResourceLabel = Roact.Component:extend("ResourceLabel")

local largeIds = {
    Food = {Positive = "rbxassetid://3144305819", Negative = "rbxassetid://3144305750"},
    Wood = {Positive = "rbxassetid://3144182791", Negative = "rbxassetid://3144182667"},
    Stone = {Positive = "rbxassetid://3144305681", Negative = "rbxassetid://3144305559"},
}

local smallIds = {
    Food = "rbxassetid://3064039406",
    Wood = "rbxassetid://3064039535",
    Stone = "rbxassetid://3064039482"
}

local largeSize = UDim2.new(0, 208, 0, 54)
local smallSize = UDim2.new(0, 82, 0, 32)

function ResourceLabel:init(props)
    self:setState(props)
    self.state.change = 0
    self.state.pastValues = {}
    self.state.display = self.state.display or 0
    self.state.lastupdate = tick()
end

function ResourceLabel:render()

    local size, id, textSize
    local displayValue = math.floor(self.state.display + 0.5)
    local elements = {}

    if self.state.Small then
        size = smallSize
        id = smallIds[self.state.Type]
        textSize = 18

        elements.Label = Roact.createElement(Label, {
            Text = displayValue, 
            TextSize = textSize, 
            Position = UDim2.new(0, 10, 0, -2),
        })
    else
        size = largeSize
        id = self.state.change < 0 and largeIds[self.state.Type].Negative or largeIds[self.state.Type].Positive
        textSize = 26

        elements.Label = Roact.createElement(Label, {
            Text = displayValue, 
            TextSize = textSize, 
            Position = UDim2.new(0, 60, 0, -2),
            XAlign = "Left",
        })

        elements.Change = Roact.createElement(Label, {
            Text = self.state.change, 
            TextSize = textSize, 
            Position = UDim2.new(0, 165, 0, -2),
            XAlign = "Left",
            Color = Color3.fromRGB(215,215,215)
        })
    end



    return Roact.createElement("ImageLabel", {
        Name                   = "ResLabel",
        BackgroundTransparency = 1,
        Position               = self.state.Position,
        Size                   = size,
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        Image                  = id,
        ImageTransparency      = 0.1,
        AnchorPoint            = Vector2.new(0, 1)
        }, elements)
end

function ResourceLabel:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                local cval = state.display or 0
                local tval = self.state.stats[self.state.Type]
                local newval = cval + (tval - cval)*0.1
                local pastvals = self.state.pastValues

                if tick() - self.state.lastupdate < 1 then
                    return {
                        display = newval,
                    }
                end

                self.state.lastupdate = tick()

                local cost = self.state.stats[self.state.Type.."Cost"] or 0
                local produce = self.state.stats[self.state.Type.."Produced"] or 0

                return {
                    display = newval,
                    change = math.floor(produce - cost),
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