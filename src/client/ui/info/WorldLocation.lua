local Client = script.Parent.Parent.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local ClientUtil    = require(Client.ClientUtil)
local Util          = require(Common.Util)
local Roact         = require(game.ReplicatedStorage.Roact)
local WorldLocation = Roact.Component:extend("WorldLocation")
local RunService    = game:GetService("RunService")

function WorldLocation:init()
    self:setState({
        location = "x: 0  y: 0",
    })
end

function WorldLocation:render()
    return Roact.createElement("TextLabel", {
        Name                   = "WorldLocation",
        BackgroundTransparency = 1,
        Position               = UDim2.new(1, -10, 0, 5),
        Size                   = UDim2.new(0, 10, 0, 10),
        AnchorPoint            = Vector2.new(1, 0),
        TextSize               = "18",
        TextColor3             = Color3.new(1,1,1),
        Text                   = self.state.location,
        TextXAlignment         = "Right",
        Font                   = "SourceSans",
    })
end

function WorldLocation:didMount()
    self.running = true

    spawn(function()
        while self.running do

            self:setState(function(state)
                local location = ClientUtil.getPlayerPosition()
                local axialLocation = Util.worldCoordToAxialCoord(location)

                return {
                    location = string.format("x: %d  y: %d", axialLocation.x, axialLocation.y)
                }
            end)

            RunService.Stepped:Wait()
        end
    end)
end

function WorldLocation:willUnmount()
    self.running = false
end

return WorldLocation