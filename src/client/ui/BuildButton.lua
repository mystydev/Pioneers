local ui = script.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local SoundManager = require(Client.SoundManager)
local Tile = require(Common.Tile)
local BuildList = require(ui.BuildList)
local ResourceLabel = require(ui.ResourceLabel)

local BuildButton = Roact.Component:extend("BuildButton")

local requirements = {Food = 0, Wood = 0, Stone = 0}

local function setHoverType(type)
    for res, amount in pairs(Tile.ConstructionCosts[type]) do
        requirements[res] = amount
    end
end

function BuildButton:init(props)
    self:setState(props)
end

function BuildButton:render()

    local elements = self.state.buildList or {}

    elements.foodlabel = Roact.createElement(ResourceLabel, {Small = true, Type = "Food", Position = UDim2.new(0, -100, 0, -10), stats = requirements})
    elements.woodlabel = Roact.createElement(ResourceLabel, {Small = true, Type = "Wood", Position = UDim2.new(0, -100, 0, 30), stats = requirements})
    elements.stonelabel = Roact.createElement(ResourceLabel, {Small = true, Type = "Stone", Position = UDim2.new(0, -100, 0, 70), stats = requirements})

    return Roact.createElement("ImageButton", {
        Name                   = "BuildButton",
        BackgroundTransparency = 1,
        Position               = self.state.Position,
        Size                   = UDim2.new(0,64,0,64),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3064009593",
        HoverImage             = "rbxassetid://3064053551",
        PressedImage           = "rbxassetid://3064053551",
        [Roact.Event.MouseButton1Click] = function() self:setState({buildList = BuildList.generate(setHoverType)}) end,
        [Roact.Event.MouseButton2Click] = function() self:setState({buildList = nil}) end, --TODO: Fix this
        [Roact.Event.MouseEnter] = SoundManager.highlight,
    }, self.state.buildList)
end

return BuildButton