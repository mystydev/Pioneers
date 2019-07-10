local UIBase = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ui     = Client.ui
local Roact  = require(game.ReplicatedStorage.Roact)

local Util                = require(Common.Util)
local Tile                = require(Common.Tile)
local ViewTile            = require(Client.ViewTile)
local ActionHandler       = require(Client.ActionHandler)
local StatsPanel          = require(ui.StatsPanel)
local InitiateBuildButton = require(ui.build.InitiateBuildButton)
local BuildList           = require(ui.build.BuildList)

local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local UIS                 = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")

UIBase.State = {}
UIBase.State.MAIN = 1
UIBase.State.BUILD = 2
UIBase.State.TILEBUILD = 3

local listHandle
local currentWorld = {}
local highlighted  = {}
local instChanges  = {}
local instEvents   = {}
local UIState      = UIBase.State.MAIN
local player       = Players.LocalPlayer
local worldgui     = Instance.new("ScreenGui", player.PlayerGui)
local screengui    = Instance.new("ScreenGui", player.PlayerGui)
local viewport     = Instance.new("ViewportFrame", worldgui)
local blur         = Instance.new("BlurEffect")
local desaturate   = Lighting.BaseCorrection
local tweenSlow    = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenFast    = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local buildButtonPosition = UDim2.new(0, 25, 1, -85)

function UIBase.init(world)
    currentWorld = world
    worldgui.Name = "World UI"
    screengui.Name = "Screen UI"
    screengui.DisplayOrder = 2
    blur.Size = 0
    blur.Parent = Lighting
    desaturate.Saturation = 0.5
    desaturate.Parent = Lighting
    viewport.Size = UDim2.new(1, 0, 1, 36)
    viewport.Position = UDim2.new(0, 0, 0, -36)
    viewport.BackgroundTransparency = 1
    viewport.CurrentCamera = workspace.CurrentCamera
    viewport.Ambient = Color3.new(1, 1, 1)
    viewport.LightColor = Color3.new(1, 1, 1)
    viewport.LightDirection = Vector3.new(0, -1, 0)
end

function UIBase.unfocusBackground()
    TweenService:Create(blur, tweenSlow, {Size = 20}):Play()
    TweenService:Create(desaturate, tweenSlow, {Saturation = -0.5}):Play()
end

function UIBase.refocusBackground()
    TweenService:Create(blur, tweenSlow, {Size = 0}):Play()
    TweenService:Create(desaturate, tweenFast, {Saturation = 0.5}):Play()
end

function UIBase.highlightInst(inst, transparency)
    if inst and not highlighted[inst] then

        local clone = inst:Clone()
        clone.Transparency = transparency or 0
        highlighted[inst] = clone
        clone.Parent = viewport

        instChanges[inst] = inst.Changed:Connect(function()
            UIBase.unHighlightInst(inst)
            UIBase.highlightInst(inst, transparency)
        end)

        return clone
    end
end

function UIBase.listenToInst(inst, onClick, onHoverIn, onHoverOut)
    instEvents[inst] = {
        onClick = onClick,
        onHoverIn = onHoverIn,
        onHoverOut = onHoverOut,
    }
end

function UIBase.unHighlightInst(inst)
    local clone = highlighted[inst]
    
    instEvents[inst] = nil
    highlighted[inst] = nil

    if instChanges[inst] then
        instChanges[inst]:Disconnect()
        instChanges[inst] = nil
    end

    if clone then
        clone:Destroy()
    end
end

function UIBase.unHighlightAllInsts()
    for inst, clone in pairs(highlighted) do
        UIBase.unHighlightInst(inst)
    end
end

function UIBase.showStats(stats)
    Roact.mount(Roact.createElement(StatsPanel, {stats = stats}), screengui)
end

function UIBase.showBuildButton()
    Roact.mount(Roact.createElement(InitiateBuildButton, {
        Position = buildButtonPosition, 
        UIBase = UIBase,
    }), screengui)
end

function UIBase.showBuildList()
    if UIState == UIBase.State.MAIN then
        listHandle = Roact.mount(Roact.createElement(BuildList, {Position = buildButtonPosition, UIBase = UIBase}), screengui)
        UIBase.transitionToBuildView()
    end
end

function UIBase.hideBuildList()
    if UIState == UIBase.State.BUILD or UIState == UIBase.State.TILEBUILD then
        Roact.unmount(listHandle)
        listHandle = nil
        UIBase.exitBuildView()
    end
end

function UIBase.exitBuildView()
    UIState = UIBase.State.MAIN
    UIBase.unHighlightAllInsts()
    UIBase.refocusBackground()
end

function UIBase.transitionToBuildView()
    UIState = UIBase.State.BUILD
    UIBase.unfocusBackground()
end

function UIBase.highlightType(type, showBuildable)
    UIBase.unHighlightAllInsts()
    local tiles = ViewTile.getPlayerTiles()
    
    for inst, tile in pairs(tiles) do
        if tile.Type == type then
            UIBase.highlightInst(inst)
        end
    end

    if showBuildable then
        UIBase.highlightBuildableArea(type)
    end
end

function UIBase.highlightBuildableTile(tile, type)
    local inst = ViewTile.getInstFromTile(tile)
    local clone = UIBase.highlightInst(inst, 0.5)
    if clone then
        UIBase.listenToInst(inst,
            function() 
                ActionHandler.attemptBuild(tile, type)
                UIBase.highlightType(type, true)
            end, 
            function() clone.Transparency = 0 end,
            function() clone.Transparency = 0.5 end)
    end
end

function UIBase.highlightBuildableArea(type)
    local buildableTiles = {}
    local tiles = ViewTile.getPlayerTiles()

    for _, tile in pairs(tiles) do
        if Util.isWalkable(tile) then
            for _, neighbour in pairs(Util.getNeighbours(currentWorld.Tiles, tile.Position)) do
                if neighbour.Type == Tile.GRASS then
                    UIBase.highlightBuildableTile(neighbour, type)
                end
            end
        end
    end
end

local lastHover
local mouse = player:GetMouse()
local function mouseMoved(input)
    local inst = mouse.Target

    if lastHover and lastHover ~= inst and instEvents[lastHover] and instEvents[lastHover].onHoverOut then
        instEvents[lastHover].onHoverOut()
        lastHover = nil
    end

    if lastHover ~= inst and instEvents[inst] and instEvents[inst].onHoverIn then
        instEvents[inst].onHoverIn()
        lastHover = inst
    end
end

local function mouseClicked(input)
    local inst = mouse.Target

    if instEvents[inst] and instEvents[inst].onClick then
        instEvents[inst].onClick()
    end
end

local function processInput(input, processed)
    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        mouseMoved(input)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 
        and input.UserInputState == Enum.UserInputState.End then
        mouseClicked(input)
    end
end

UIS.InputBegan:Connect(processInput)
UIS.InputChanged:Connect(processInput)
UIS.InputEnded:Connect(processInput)

return UIBase