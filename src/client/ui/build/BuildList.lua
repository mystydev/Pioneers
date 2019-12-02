local ui = script.Parent.Parent
local Client = ui.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local Common = game.ReplicatedStorage.Pioneers.Common
local TweenService = game:GetService("TweenService")

local Tile = require(Common.Tile)
local UserStats = require(Common.UserStats)
local SoundManager = require(Client.SoundManager)
local Replication = require(Client.Replication)
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

    local stats = Replication.getUserStats()

    if not UserStats.hasUnlocked(stats, self.props.type) then
        return nil
    end

    local req = Tile.ConstructionCosts[self.props.type]
    local canAfford = UserStats.hasEnoughResources(stats, req)

    local onClick
    
    onClick = function()
        if UserStats.hasEnoughResources(stats, req) then
            self.props.UIBase.highlightType(self.props.type, true)
        end
    end

    return Roact.createElement("ImageButton", {
        Name                   = self.props.type,
        BackgroundTransparency = 1,
        ImageTransparency      = 1,
        Position               = self.props.position,
        Size                   = UDim2.new(0,60,0,60),
        AnchorPoint            = Vector2.new(0, 1),
        Image                  = self.props.imageId,
        ZIndex                 = 2,
        ImageColor3            = canAfford and Color3.new(1,1,1) or Color3.new(0.95, 0.2, 0.2),
        [Roact.Ref]            = self.instRef,
        [Roact.Event.MouseButton1Click] = onClick,
        [Roact.Event.MouseEnter] = function(x, y) SoundManager.rollover() showToolTip(self.props.buildList, self.props.position, self.props.type) end,
        [Roact.Event.MouseMoved] = function(x, y) showToolTip(self.props.buildList, self.props.position, self.props.type) end,
        [Roact.Event.MouseLeave] = function(x, y) hideToolTip(self.props.buildList, self.props.position, self.props.type) end,
    })
end

function Button:didMount()
    if self.instRef:getValue() then
        TweenService:Create(self.instRef:getValue(), transparencyTween, {ImageTransparency = 0}):Play()
    end
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
    buttons.Path     = button(self, UDim2.new(0,  1 * 60, 0, 0), Tile.PATH,     "rbxassetid://3480834893")
    buttons.House    = button(self, UDim2.new(0,  2 * 60, 0, 0), Tile.HOUSE,    "rbxassetid://3464266043")
    buttons.Farm     = button(self, UDim2.new(0,  3 * 60, 0, 0), Tile.FARM,     "rbxassetid://3464265775")
    buttons.Forestry = button(self, UDim2.new(0,  4 * 60, 0, 0), Tile.FORESTRY, "rbxassetid://3464265858")
    buttons.Mine     = button(self, UDim2.new(0,  5 * 60, 0, 0), Tile.MINE,     "rbxassetid://3480834162")
    buttons.Storage  = button(self, UDim2.new(0,  6 * 60, 0, 0), Tile.STORAGE,  "rbxassetid://3480834300")
    buttons.Barracks = button(self, UDim2.new(0,  7 * 60, 0, 0), Tile.BARRACKS, "rbxassetid://3464265681")
    buttons.Wall     = button(self, UDim2.new(0,  8 * 60, 0, 0), Tile.WALL,     "rbxassetid://3480834420")
    buttons.Gate     = button(self, UDim2.new(0,  9 * 60, 0, 0), Tile.GATE,     "rbxassetid://3480834049")

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
        Position               = UDim2.new(0, 670, 1, -12),
        Size                   = UDim2.new(0,0,0,0),
        AnchorPoint            = Vector2.new(0, 1),
    }, buttons)
end

return BuildList