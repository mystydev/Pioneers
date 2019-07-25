local ObjectSelection = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact  = require(game.ReplicatedStorage.Roact)

local ViewTile        = require(Client.ViewTile)
local ViewWorld       = require(Client.ViewWorld)
local Replication     = require(Client.Replication)
local SoundManager    = require(Client.SoundManager)
local Tile            = require(Common.Tile)
local World           = require(Common.World)
local Util            = require(Common.Util)

local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player     = Players.LocalPlayer
local sgui       = Instance.new("ScreenGui", player.PlayerGui)
local viewport   = Instance.new("ViewportFrame", sgui)
local blur       = Instance.new("BlurEffect")
local desaturate = Lighting.BaseCorrection
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

    if inst and inst.Parent.ClassName == "Model" then
        inst = inst.Parent
    end

    return ViewWorld.convertInstanceToObject(inst), inst
end

local function focusInst(inst)
    if inst then
        focusedInsts[inst] = true
    end
end

local tempinsts = {}
local function tempUnfocusInsts()

    for inst, _ in pairs(focusedInsts) do
        if inst:IsA("MeshPart") then
            tempinsts[inst] = true
            focusedInsts[inst] = nil
        end
    end
end

local function refocusTempInsts()
    for inst, _ in pairs(tempinsts) do
        tempinsts[inst] = nil
        focusedInsts[inst] = true
    end
end

local function unselect(dontunmount)
    currentSelectionInfo.Obj = Roact.None
    
    refocusTempInsts()

    for inst, _ in pairs(focusedInsts) do
        focusedInsts[inst] = nil
    end


    TweenService:Create(blur, tweenFast, {Size = 0}):Play()
    TweenService:Create(desaturate, tweenFast, {Saturation = 0.5}):Play()

    if not dontunmount then
        local panel = Roact.createElement(ObjectInfoPanel, {info = currentSelectionInfo})
        handle = Roact.update(handle, panel)
        inPrompt = nil
        SoundManager.endFocus()
    end
end

local function select(object, inst, reselect)
    unselect(true)

    if not reselect then
        SoundManager.pullFocus()
    end

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

    if selectedObject.UnitList then
        for _, unitid in pairs(selectedObject.UnitList) do
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
    if not currentWorld or currentWorld.Dead or processed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseClicked()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        unselect()
    elseif input.UserInputType == Enum.UserInputType.Touch then
        mouseClicked()
    end
end


local function updateWiggle()
    
    while RunService.Stepped:Wait() do

        for inst, _ in pairs(wiggleinsts) do
            wiggleinsts[inst]:Destroy()
        end

        for inst, _ in pairs(focusedInsts) do
            wiggleinsts[inst] = inst:Clone()
            wiggleinsts[inst].Parent = viewport 
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

local function getNeighbours(tile)
    local tiles = currentWorld.Tiles
    local pos = tile.Position

    return {
        World.getTile(tiles, pos.x    , pos.y + 1),
        World.getTile(tiles, pos.x + 1, pos.y + 1),
        World.getTile(tiles, pos.x + 1, pos.y    ),
        World.getTile(tiles, pos.x    , pos.y - 1),
        World.getTile(tiles, pos.x - 1, pos.y - 1),
        World.getTile(tiles, pos.x - 1, pos.y    ),
    }
end

function ObjectSelection.buildTileAtSelection(tileType)
    if not selectedObject then return warn("Attempted to place tile when a tile is not selected!") end
    if selectedObject.Id then return warn("Attempted to place tile on a unit!") end

    SoundManager.initiatePlace()

    selectedObject.Type = tileType
    selectedObject.lastChange = tick()

    --Predict build is ok
    ViewTile.updateDisplay(selectedObject)

    for _, n in pairs(Util.getNeighbours(currentWorld.Tiles, selectedObject.Position)) do
        ViewTile.updateDisplay(n)
    end

    select(selectedObject, nil, true)

    if tileType == Tile.KEEP then
        delay(0.2, function()
            for _, tile in pairs(getNeighbours(selectedObject)) do
                tile.Type = Tile.PATH
                tile.lastChange = tick()
                ViewTile.updateDisplay(tile)
            end
        end)
    end

    local status = Replication.requestTilePlacement(selectedObject, tileType)

    if status then
        SoundManager.success()
    end
end

--Async!
function ObjectSelection.startUnitTileSelectPrompt(action)
    TweenService:Create(blur, tweenSlow, {Size = 5}):Play()

    tempUnfocusInsts()

    local tempFocused = {}

    if action == World.Actions.SET_WORK then
        for index, tile in pairs(currentWorld.Tiles) do
            if (tile.Type == Tile.FARM
                or tile.Type == Tile.FORESTRY
                or tile.Type == Tile.MINE
                or tile.Type == Tile.BARRACKS) 
                and #(tile.UnitList or {}) == 0 then

                local inst = ViewWorld.convertObjectToInst(tile)
                focusInst(inst)
                tempFocused[inst] = true
            end
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

    if inPrompt then
        TweenService:Create(blur, tweenSlow, {Size = 20}):Play()
        inPrompt = nil
        return object
    else
        return nil
    end
end

function ObjectSelection.assignTilePrompt(action)
    local tile = ObjectSelection.startUnitTileSelectPrompt(action)

    if tile then
        local status

        if action == World.Actions.SET_WORK then
            status = Replication.requestUnitWork(selectedObject, tile)
        elseif action == World.Actions.ATTACK then
            status = Replication.requestUnitAttack(selectedObject, tile)
        end

        if status then
            SoundManager.success()
        end

        unselect()
    end
end

UIS.InputBegan:Connect(processInput)

ObjectSelection.select = select

return ObjectSelection