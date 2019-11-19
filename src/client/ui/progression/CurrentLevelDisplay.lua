local Client = script.Parent.Parent.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ui     = Client.ui
local Roact  = require(game.ReplicatedStorage.Roact)

local Tile = require(Common.Tile)
local Replication = require(Client.Replication)
local Label = require(ui.Label)
local Title = require(ui.Title)

local CurrentLevelDisplay = Roact.Component:extend("CurrentLevelDisplay")
local gameSettings

local function translateRequirement(req)
    local type, index = unpack(string.split(req, ":"))
    
    if type == "Built" then
        return Tile.Localisation[tonumber(index)]
    elseif type == "Population" then
        return index .. " Population"
    end
end

local function textWithShadow(text, position)
    return Roact.createElement(Label, {
        Text = text,
        Position = position,
        Color = Color3.fromRGB(33, 33, 33),
        TextSize = 28,
        XAlign = "Left",
        AnchorPoint = Vector2.new(0, 0),
    }, {
        white = Roact.createElement(Label, {
            Text = text,
            Position = UDim2.new(0, -1, 0, -1),
            Size = UDim2.new(1, 0, 1, 0),
            Color = Color3.fromRGB(255, 255, 255),
            TextSize = 28,
            XAlign = "Left",
            AnchorPoint = Vector2.new(0, 0),
        })
    })
end

function CurrentLevelDisplay:init()
    gameSettings = Replication.getGameSettings()
end

function CurrentLevelDisplay:render()

    local elements = {}
    local currentLevel = self.props.stats.Level

    elements.title = Roact.createElement(Title, {
        Title = "Goals for next Level",
        TextSize = 32,
        Position = UDim2.new(0.5, 50, 0, 55),
    })

    elements.level = Roact.createElement(Title, {
        Title = currentLevel,
        Position = UDim2.new(0, 67, 0, 65),
        Color = Color3.fromRGB(255, 255, 255),
    })

    -- +1 because lua is dumb and starts arrays at 1, offsetting json arrays by 1
    local requirements = gameSettings.level_requirements[tonumber(currentLevel) + 1]
    local index = 1

    for type, value in pairs(requirements) do
        if type ~= "Unlocks" then
            local text = translateRequirement(type) .. "    " .. (self.props.stats[type] or 0) .. " / " .. value
            elements[tostring(index)] = textWithShadow(text, UDim2.new(0, 100, 0, 20 + 25 * index))
            index = index + 1
        end
    end

    return Roact.createElement("ImageLabel", {
        Size = UDim2.new(0, 367, 0, 137),
        Position = UDim2.new(0, 0, 0, 30),
        Image = "rbxassetid://4423630492",
        BackgroundTransparency = 1,
    }, elements)
end

function CurrentLevelDisplay:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState({})
            wait(0.5)
        end
    end)
end

function CurrentLevelDisplay:willUnmount()
    self.running = false
end

return CurrentLevelDisplay