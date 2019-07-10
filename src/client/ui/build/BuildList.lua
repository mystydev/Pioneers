local ui = script.Parent.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local Common = game.ReplicatedStorage.Pioneers.Common
local TweenService = game:GetService("TweenService")

local Tile = require(Common.Tile)
local BuildToolTip = require(ui.build.BuildToolTip)
local BuildList = Roact.Component:extend("BuildList")

local buttons = {}
local transparencyTween = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local toolTipPosBinding, toolTipPos = Roact.createBinding(UDim2.new(0,0,0,0))
local toolTipShowBinding, toolTipShow = Roact.createBinding(1)
local toolTipTypeBinding, toolTipType = Roact.createBinding("Unknown")

local function showToolTip(buildList, position, type)
    toolTipPos(position)
    toolTipShow(0)
    toolTipType(type)
end

local function hideToolTip(buildList, position, type)
    toolTipShow(1)
end

local Button = Roact.Component:extend("Button")

function Button:init()
    self.instRef = Roact.createRef()
end

function Button:render()
    return Roact.createElement("ImageButton", {
        Name                   = self.props.type,
        BackgroundTransparency = 1,
        ImageTransparency      = 1,
        Position               = self.props.position,
        Size                   = UDim2.new(0,50,0,50),
        AnchorPoint            = Vector2.new(0, 1),
        Image                  = self.props.imageId,
        [Roact.Ref]            = self.instRef,
        [Roact.Event.MouseButton1Click] = function() self.props.UIBase.highlightType(self.props.type, true) end,
        [Roact.Event.MouseEnter] = function(x, y) showToolTip(self.props.buildList, self.props.position, self.props.type) end,
        [Roact.Event.MouseMoved] = function(x, y) showToolTip(self.props.buildList, self.props.position, self.props.type) end,
        [Roact.Event.MouseLeave] = function(x, y) hideToolTip(self.props.buildList, self.props.position, self.props.type) end,
    })
end

function Button:didMount()
    TweenService:Create(self.instRef:getValue(), transparencyTween, {ImageTransparency = 0}):Play()
end

function button(buildList, position, type, imageId)
    return Roact.createElement(Button, {
        buildList = buildList,
        UIBase = buildList.props.UIBase,
        position = position, 
        type = type,
        imageId = imageId,
    })
end

function BuildList:init()
    buttons.Keep     = button(self, UDim2.new(0,  50, 0, 0), Tile.KEEP,     "rbxassetid://3437127076")
    buttons.Path     = button(self, UDim2.new(0, 100, 0, 0), Tile.PATH,     "rbxassetid://3437127257")
    buttons.House    = button(self, UDim2.new(0, 150, 0, 0), Tile.HOUSE,    "rbxassetid://3437126939")
    buttons.Farm     = button(self, UDim2.new(0, 200, 0, 0), Tile.FARM,     "rbxassetid://3437122723")
    buttons.Forestry = button(self, UDim2.new(0, 250, 0, 0), Tile.FORESTRY, "rbxassetid://3437122827")
    buttons.Mine     = button(self, UDim2.new(0, 300, 0, 0), Tile.MINE,     "rbxassetid://3437127172")
    buttons.Storage  = button(self, UDim2.new(0, 350, 0, 0), Tile.STORAGE,  "rbxassetid://3437127343")
    buttons.Barracks = button(self, UDim2.new(0, 400, 0, 0), Tile.BARRACKS, "rbxassetid://3437122460")
    buttons.Wall     = button(self, UDim2.new(0, 450, 0, 0), Tile.WALL,     "rbxassetid://3437130766")
    buttons.Gate     = button(self, UDim2.new(0, 500, 0, 0), Tile.GATE,     "rbxassetid://3437122930")

    buttons.toolTip = Roact.createElement(BuildToolTip, {
        Position = toolTipPosBinding, 
        Showing = toolTipShowBinding,
        Type = toolTipTypeBinding,
    })
end

function BuildList:render()
    return Roact.createElement("Frame", {
        Name                   = "BuildList",
        BackgroundTransparency = 1,
        Position               = self.props.Position,
        Size                   = UDim2.new(0,0,0,0),
        AnchorPoint            = Vector2.new(0, 1),
    }, buttons)
end

return BuildList