local ObjectSelection = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact  = require(game.ReplicatedStorage.Roact)

local ViewTile        = require(Client.ViewTile)
local ViewWorld       = require(Client.ViewWorld)
local Replication     = require(Client.Replication)
local Tile            = require(Common.Tile)

local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player     = Players.LocalPlayer
local sgui       = Instance.new("ScreenGui", player.PlayerGui)
local viewport   = Instance.new("ViewportFrame", sgui)
local blur       = Instance.new("BlurEffect")
local desaturate = Instance.new("ColorCorrectionEffect")
local tweenSlow  = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenFast  = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local ObjectInfoPanel
local handle
local currentWorld
local currentStats
local selectedObject
local focusedInsts = {}
local wiggleinsts = {}
local inPrompt

local currentSelectionInfo = {Obj = object, World = currentWorld, stats = currentStats}

local function getObjectAtMouse()
    local mouse = player:GetMouse()

    local inst = mouse.Target

    if inst and inst.Parent.Name == "Dummy" then --TODO: more robust!
        inst = inst.Parent
    end

    return ViewWorld.convertInstanceToObject(inst), inst
end

local function focusInst(inst)
    focusedInsts[inst] = true

    if inst:IsA("BasePart") then
        inst.Parent = viewport
    end
end

local tempinsts = {}
local function tempUnfocusInsts()

    for inst, _ in pairs(focusedInsts) do
        if inst.Parent == viewport and inst.Name == "Hexagon" then --TODO: Yuck
            inst.Parent = workspace
        end
    end
end

local function refocusTempInsts()
    for inst, _ in pairs(focusedInsts) do
        inst.Parent = viewport
    end
end

local function unselect(dontunmount)

    currentSelectionInfo.Obj = Roact.None
    
    for inst, _ in pairs(focusedInsts) do
        focusedInsts[inst] = nil

        if wiggleinsts[inst] then
            wiggleinsts[inst]:Destroy()
        end

        if inst.Parent == viewport then
            inst.Parent = workspace
        end
    end

    TweenService:Create(blur, tweenFast, {Size = 0}):Play()
    TweenService:Create(desaturate, tweenFast, {Saturation = 0.5}):Play()

    if not dontunmount then
        local panel = Roact.createElement(ObjectInfoPanel, {info = currentSelectionInfo})
        handle = Roact.reconcile(handle, panel)
        inPrompt = nil
    end
end

local function select(object, inst)
    unselect(true)

    TweenService:Create(blur, tweenSlow, {Size = 20}):Play()
    TweenService:Create(desaturate, tweenSlow, {Saturation = -0.5}):Play()

    focusInst(inst or ViewWorld.convertObjectToInst(object))

    selectedObject = object
    currentSelectionInfo.Obj = object

    if selectedObject.Home then
        focusInst(ViewWorld.convertObjectToInst(currentWorld.Tiles[Tile.getIndex(selectedObject.Home)]))
    end

    if selectedObject.Work then
        focusInst(ViewWorld.convertObjectToInst(currentWorld.Tiles[Tile.getIndex(selectedObject.Work)]))
    end

    if selectedObject.unitlist then
        for _, unitid in pairs(selectedObject.unitlist) do
            focusInst(ViewWorld.convertObjectToInst(currentWorld.Units[unitid]))
        end
    end

    local panel = Roact.createElement(ObjectInfoPanel, {info = currentSelectionInfo})
    handle = Roact.reconcile(handle, panel)
end

local function selectObjectAtMouse()
    local object, inst = getObjectAtMouse()

    if object then
        select(object, inst)
    end
end

local function mouseClicked()
    if not inPrompt then
        selectObjectAtMouse()
    else
        inPrompt()
    end
end

local function processInput(input, processed)

    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseClicked()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        unselect()
    end
end


local function updateWiggle()
    
    while RunService.Stepped:Wait() do
        for inst, _ in pairs(focusedInsts) do
            if inst.ClassName == "Model" then

                if wiggleinsts[inst] then
                    wiggleinsts[inst]:Destroy()
                end

                wiggleinsts[inst] = inst:Clone()
                wiggleinsts[inst].Parent = viewport
                
            end
        end
    end
end

function ObjectSelection.init(world, stats)
    sgui.Name = "Object selection view"
    ObjectInfoPanel = require(Client.ui.ObjectInfoPanel)
    
    currentWorld = world
    currentStats = stats

    currentSelectionInfo.World = world
    currentSelectionInfo.stats = stats

    local panel = Roact.createElement(ObjectInfoPanel, {info = currentSelectionInfo})
    handle = Roact.mount(panel, sgui, "Object info panel")

    blur.Size = 0
    blur.Parent = Lighting
    desaturate.Saturation = 0.5
    desaturate.Parent = Lighting
    viewport.Size = UDim2.new(1, 0, 1, 36)
    viewport.Position = UDim2.new(0, 0, 0, -36)
    viewport.BackgroundTransparency = 1
    viewport.CurrentCamera = workspace.CurrentCamera

    spawn(updateWiggle)
end

function ObjectSelection.buildTileAtSelection(tileType)
    if not selectedObject then return warn("Attempted to place tile when a tile is not selected!") end
    if selectedObject.Id then return warn("Attempted to place tile on a unit!") end

    selectedObject.Type = tileType
    ViewTile.updateDisplay(selectedObject) --Predict build is ok

    Replication.requestTilePlacement(selectedObject, tileType)
end

--Async!
function ObjectSelection.startUnitTileSelectPrompt()
    TweenService:Create(blur, tweenSlow, {Size = 5}):Play()

    tempUnfocusInsts()

    local tempFocused = {}

    for index, tile in pairs(currentWorld.Tiles) do
        if tile.Type == Tile.FARM and #tile.unitlist == 0 then
            local inst = ViewWorld.convertObjectToInst(tile)
            focusInst(inst)
            tempFocused[inst] = true
        end
    end

    local object

    inPrompt = function()
        obj = getObjectAtMouse()

        if obj and not obj.Id then 
            object = obj
        end
    end

    repeat wait(0.1)
    until object or not inPrompt

    for inst, _ in pairs(tempFocused) do
        inst.Parent = workspace
        focusedInsts[inst] = nil
    end

    refocusTempInsts()

    if object then
        focusInst(ViewWorld.convertObjectToInst(object))
    end

    if inPrompt then
        TweenService:Create(blur, tweenSlow, {Size = 20}):Play()
        inPrompt = nil
        return object
    else
        return nil
    end
end

function ObjectSelection.assignWorkPrompt()
    local tile = ObjectSelection.startUnitTileSelectPrompt()

    if tile then
        Replication.requestUnitWork(selectedObject, tile)
    end
end

UIS.InputBegan:Connect(processInput)

ObjectSelection.select = select

return ObjectSelection