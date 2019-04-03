local ViewStats = {}
local Common = game.ReplicatedStorage.Pioneers.Common
local UserStats = require(Common.UserStats)
local Resource = require(Common.Resource)
local Roact = require(game.ReplicatedStorage.Roact)

local ResView = Roact.Component:extend("ResView")
local DisplayHandle
ViewStats.CurrentStats = nil

function ResView:init()
    self:setState({stats = ViewStats.CurrentStats})
end

function ResView:render()
    local stats = self.state.stats

    local text = ""
    text = text .. "🍞" .. stats.Food .. "    "
    text = text .. "🌳" .. stats.Wood .. "    "
    text = text .. "⛏️" .. stats.Stone .. "    "

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
    function self.state.stats.changed()
        self:setState(self.state)
    end
end

function ResView:willUnmount()
    self.state.changed = function() end
end

function ViewStats.createDisplay(stats)
    ViewStats.CurrentStats = stats
    displayHandle = Roact.mount(Roact.createElement(ResView), game.Players.LocalPlayer.PlayerGui, "Resource View")
end

function ViewStats.removeDisplay()
    Roact.unmount(displayHandle)
end

return ViewStats