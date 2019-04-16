local ObjectSelection = {}
local Client = script.Parent
local Roact  = require(game.ReplicatedStorage.Roact)

local ViewTile        = require(Client.ViewTile)
local ViewWorld       = require(Client.ViewWorld)
local Replication     = require(Client.Replication)

local UIS          = game:GetService("UserInputService")
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player     = Players.LocalPlayer
local sgui       = Instance.new("ScreenGui", player.PlayerGui)
local viewport   = Instance.new("ViewportFrame", sgui)
local cam        = Instance.new("Camera")
local blur       = Instance.new("BlurEffect")
local desaturate = Instance.new("ColorCorrectionEffect")
local tweenSlow  = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenFast  = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local ObjectInfoPanel
local handle
local currentWorld
local selectedObject
local focusedInsts = {}
local inPrompt

local function getObjectAtMouse()
    local mouse = player:GetMouse()

    local inst = mouse.Target

    return ViewWorld.convertInstanceToObject(inst), inst
end

function ObjectSelection.init(world)
    ObjectInfoPanel = require(Client.ui.ObjectInfoPanel)
    handle = Roact.mount(Roact.createElement(ObjectInfoPanel), sgui)

    currentWorld = world

    blur.Size = 0
    blur.Parent = Lighting
    desaturate.Saturation = 0
    desaturate.Parent = Lighting
    viewport.Size = UDim2.new(1, 0, 1, 36)
    viewport.Position = UDim2.new(0, 0, 0, -36)
    viewport.BackgroundTransparency = 1
    viewport.CurrentCamera = workspace.CurrentCamera
end

function ObjectSelection.buildTileAtSelection(tileType)
    if not selectedObject then return warn("Attempted to place tile when a tile is not selected!") end
    if selectedObject.ID then return warn("Attempted to place tile on a unit!") end

    selectedObject.Type = tileType
    ViewTile.updateDisplay(selectedObject) --Predict build is ok

    Replication.requestTilePlacement(selectedObject, tileType)
end

--Async!
function ObjectSelection.startUnitTileSelectPrompt()
    TweenService:Create(blur, tweenSlow, {Size = 5}):Play()

    local object

    inPrompt = function()
        obj = getObjectAtMouse()

        if obj and not obj.ID then 
            object = obj
        end
    end

    repeat wait(0.1)
    until object or not inPrompt

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
        Replication.requestUnitWork(selectedObject,tile)
    end
end

local function focusInst(inst)
    inst.Parent = viewport
    focusedInsts[inst] = true
end

local function unselect(dontunmount)
    
    for inst, _ in pairs(focusedInsts) do
        inst.Parent = workspace
        focusedInsts[inst] = nil
    end

    TweenService:Create(blur, tweenFast, {Size = 0}):Play()
    TweenService:Create(desaturate, tweenFast, {Saturation = 0}):Play()

    if not dontunmount then
        handle = Roact.reconcile(handle, ObjectInfoPanel{Obj = nil, World = currentWorld})
        inPrompt = nil
    end
end

local function select(object, inst)
    unselect(true)

    TweenService:Create(blur, tweenSlow, {Size = 20}):Play()
    TweenService:Create(desaturate, tweenSlow, {Saturation = -0.5}):Play()

    focusInst(inst or ViewWorld.convertObjectToInst(object))

    selectedObject = object
    handle = Roact.reconcile(handle, ObjectInfoPanel{Obj = object, World = currentWorld})
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

UIS.InputBegan:Connect(processInput)

ObjectSelection.select = select

return ObjectSelection