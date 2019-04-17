local ViewStats = {}
local ui        = script.Parent.ui
local Roact     = require(game.ReplicatedStorage.Roact)

local Players    = game:GetService("Players")
local StatsPanel = require(ui.StatsPanel)

local player     = Players.LocalPlayer
local sgui       = Instance.new("ScreenGui", player.PlayerGui)
local handle

function ViewStats.init(stats)
    sgui.Name = "Stats view"
    handle = Roact
    Roact.mount(Roact.createElement(StatsPanel, {stats = stats}), sgui)
end

return ViewStats