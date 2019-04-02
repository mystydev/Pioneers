local ViewResources = {}
local Common = game.ReplicatedStorage.Pioneers.Common
local UserStats = require(Common.UserStats)
local Resource = require(Common.Resource)
local Roact = require(game.ReplicatedStorage.Roact)

local ResView = Roact.Component:extend("ResView")
local DisplayHandle

function ResView:init()
    self:setState(UserStats.new({
        Resource.new(Resource.WOOD, 10),
        Resource.new(Resource.FOOD, 23),
        Resource.new(Resource.STONE, 16)
    },0,0,0))
end

function ResView:render()
    local res = self.state.Resources

    local text = ""

    for i, res in pairs(res) do
        text = text .. res.Amount .. res.Type .. "    "
    end

    return Roact.createElement("ScreenGui", {}, {
        ResLabel = Roact.createElement("TextLabel", {
            Size = UDim2.new(0, 300, 0, 40),
            Position = UDim2.new(0, 0, 1, -40),
            TextSize = 15,
            Text = text
        })
    })
end

function ResView:didMount()
    
end

function ResView:willUnmount()

end

function ViewResources.createDisplay()
    displayHandle = Roact.mount(Roact.createElement(ResView), game.Players.LocalPlayer.PlayerGui, "Resource View")
end

function ViewResources.removeDisplay()
    Roact.unmount(displayHandle)
end

return ViewResources