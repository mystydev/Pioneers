local ViewSelection = {}
local Client        = script.Parent
local Common        = game.ReplicatedStorage.Pioneers.Common

local ClientUtil = require(Client.ClientUtil)
local TilePlacement = require(Client.TilePlacement)
local ViewUnit = require(Client.ViewUnit)
local UnitController = require(Client.UnitController)
local World = require(Common.World)
local Tile = require(Common.Tile)
local Unit = require(Common.Unit)

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player     = Players.LocalPlayer
local cam        = Instance.new("Camera")
local blur       = Instance.new("BlurEffect")
local desaturate = Instance.new("ColorCorrectionEffect")
local viewport
local managedinsts = {}
local numinst   = 0
local tweenSlow = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenFast = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local uitween = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local building = false
local infoui = game.StarterGui.SelectionInfo:Clone()
local currentInfoObject 
local currentWorld

local villagerInfoDisplay = {infoui.Container.VillagerInfo.Vill1, infoui.Container.VillagerInfo.Vill2}

blur.Size = 0
desaturate.Saturation = 0

local function setResReqHover(label, reqs)
    local button = infoui.Container.BuildButton
    local foodreq = button.FoodRequired
    local woodreq = button.WoodRequired
    local stonereq = button.StoneRequired

    label.InputChanged:Connect(function()
        ClientUtil.tweenLabelValue(foodreq.Label, reqs.Food)
        ClientUtil.tweenLabelValue(woodreq.Label, reqs.Wood)
        ClientUtil.tweenLabelValue(stonereq.Label, reqs.Stone)
    end)

    --label.InputEnded:Connect(function()
        --ClientUtil.tweenLabelValue(foodreq.Label, 0)
        --ClientUtil.tweenLabelValue(woodreq.Label, 0)
        --ClientUtil.tweenLabelValue(stonereq.Label, 0)
    --end)
end

setResReqHover(infoui.Container.BuildButton.BuildKeep, Tile.ConstructionCosts[Tile.KEEP])
setResReqHover(infoui.Container.BuildButton.BuildPath, Tile.ConstructionCosts[Tile.PATH])
setResReqHover(infoui.Container.BuildButton.BuildHouse, Tile.ConstructionCosts[Tile.HOUSE])
setResReqHover(infoui.Container.BuildButton.BuildFarm, Tile.ConstructionCosts[Tile.FARM])
setResReqHover(infoui.Container.BuildButton.BuildForestry, Tile.ConstructionCosts[Tile.FORESTRY])
setResReqHover(infoui.Container.BuildButton.BuildMine, Tile.ConstructionCosts[Tile.MINE])
setResReqHover(infoui.Container.BuildButton.BuildStorage, Tile.ConstructionCosts[Tile.STORAGE])

local function setTileBuild(label, type)
    label.MouseButton1Click:Connect(function()
        TilePlacement.buildTileAtSelection(type)
        ViewSelection.displayTileInfo(currentInfoObject)
    end)
end

setTileBuild(infoui.Container.BuildButton.BuildKeep, Tile.KEEP)
setTileBuild(infoui.Container.BuildButton.BuildPath, Tile.PATH)
setTileBuild(infoui.Container.BuildButton.BuildHouse, Tile.HOUSE)
setTileBuild(infoui.Container.BuildButton.BuildFarm, Tile.FARM)
setTileBuild(infoui.Container.BuildButton.BuildForestry, Tile.FORESTRY)
setTileBuild(infoui.Container.BuildButton.BuildMine, Tile.MINE)
setTileBuild(infoui.Container.BuildButton.BuildStorage, Tile.STORAGE)

local function undoBuildButton()
    building = false 

    local button = infoui.Container.BuildButton
    local foodreq = button.FoodRequired
    local woodreq = button.WoodRequired
    local stonereq = button.StoneRequired
    local buildkeep = button.BuildKeep
    local buildpath = button.BuildPath
    local buildhouse = button.BuildHouse
    local buildfarm = button.BuildFarm

    button.BuildForestry.Visible = false
    button.BuildMine.Visible = false
    button.BuildStorage.Visible = false

    foodreq.Visible = false
    woodreq.Visible = false
    stonereq.Visible = false
    buildkeep.Visible = false
    buildpath.Visible = false
    buildhouse.Visible = false
    buildfarm.Visible = false
end

local function conditionalUndo()
    if infoui.Enabled == false then
        undoBuildButton()
    end
end

local function buildButtonPressed()
    local button = infoui.Container.BuildButton
    local foodreq = button.FoodRequired
    local woodreq = button.WoodRequired
    local stonereq = button.StoneRequired
    local buildkeep = button.BuildKeep
    local buildpath = button.BuildPath
    local buildhouse = button.BuildHouse
    local buildfarm = button.BuildFarm
    local buildforestry = button.BuildForestry
    local buildmine = button.BuildMine
    local buildstorage = button.BuildStorage

    if not building then
        building = true

        foodreq.Visible = true
        woodreq.Visible = true
        stonereq.Visible = true
        buildkeep.Visible = true
        buildpath.Visible = true
        buildhouse.Visible = true
        buildfarm.Visible = true
        buildforestry.Visible = true
        buildmine.Visible = true
        buildstorage.Visible = true

        local ft = TweenService:Create(foodreq, uitween, {Position = foodreq.Position})
        local wt = TweenService:Create(woodreq, uitween, {Position = woodreq.Position})
        local st = TweenService:Create(stonereq, uitween, {Position = stonereq.Position})
        local bkt = TweenService:Create(buildkeep, uitween, {Position = buildkeep.Position})
        local bpt = TweenService:Create(buildpath, uitween, {Position = buildpath.Position})
        local bht = TweenService:Create(buildhouse, uitween, {Position = buildhouse.Position})
        local bft = TweenService:Create(buildfarm, uitween, {Position = buildfarm.Position})
        local bfot = TweenService:Create(buildforestry, uitween, {Position = buildforestry.Position})
        local bmt = TweenService:Create(buildmine, uitween, {Position = buildmine.Position})
        local bst = TweenService:Create(buildstorage, uitween, {Position = buildstorage.Position})

        foodreq.Position = UDim2.new(0,0,0,0)
        woodreq.Position = UDim2.new(0,0,0,0)
        stonereq.Position = UDim2.new(0,0,0,0)
        buildkeep.Position = UDim2.new(0,0,0,0)
        buildpath.Position = UDim2.new(0,0,0,0)
        buildhouse.Position = UDim2.new(0,0,0,0)
        buildfarm.Position = UDim2.new(0,0,0,0)
        buildforestry.Position = UDim2.new(0,0,0,0)
        buildmine.Position = UDim2.new(0,0,0,0)
        buildstorage.Position = UDim2.new(0,0,0,0)
        
        ft:Play()
        wt:Play()
        st:Play()
        bkt:Play()
        bpt:Play()
        bht:Play()
        bft:Play()
        bfot:Play()
        bmt:Play()
        bst:Play()
    else
        undoBuildButton()
    end
end

infoui.Container.BuildButton.MouseButton1Click:Connect(buildButtonPressed)
infoui.Container.BuildButton.MouseButton2Click:Connect(undoBuildButton)

function ViewSelection.createDisplay()

    local gui = Instance.new("ScreenGui", player.PlayerGui)
    gui.Name = "ViewSelection"

    viewport = Instance.new("ViewportFrame", gui)
    viewport.Size = UDim2.new(1, 0, 1, 36)
    viewport.Position = UDim2.new(0, 0, 0, -36)
    viewport.BackgroundTransparency = 1

    --infoui.Enabled = false
    --infoui.Parent = player.PlayerGui

    blur.Parent = Lighting
    desaturate.Parent = Lighting
    viewport.CurrentCamera = workspace.CurrentCamera
end

function ViewSelection.addInst(inst)
    inst.Parent = viewport
    --numinst = numinst + 1

    managedinsts[inst] = true

    infoui.Enabled = true

    TweenService:Create(blur, tweenSlow, {Size = 20}):Play()
    TweenService:Create(desaturate, tweenSlow, {Saturation = -0.5}):Play()
end

function ViewSelection.removeInst(inst)
    --inst.Parent = workspace
    --numinst = numinst - 1

    --TODO: NASTY!

    for i, v in pairs(managedinsts) do
        i.Parent = workspace
    end
    

    --if numinst <= 0 then
        infoui.Enabled = false

        spawn(conditionalUndo)
        TweenService:Create(blur, tweenFast, {Size = 0}):Play()
        TweenService:Create(desaturate, tweenFast, {Saturation = 0}):Play()
    --end
end

MAX_FATIGUE = 10
local UnitState = {} --TODO: Move this to a more appropriate place!
UnitState.IDLE = 0
UnitState.DEAD = 1
UnitState.MOVING = 2
UnitState.WORKING = 3
UnitState.RESTING = 4
UnitState.STORING = 5

local StateLocalisation = {}
StateLocalisation[UnitState.IDLE] = "Idle"
StateLocalisation[UnitState.DEAD] = "Dead"
StateLocalisation[UnitState.MOVING] = "Moving"
StateLocalisation[UnitState.WORKING] = "Working"
StateLocalisation[UnitState.RESTING] = "Resting"
StateLocalisation[UnitState.STORING] = "Storing"

local currentWorld 

local function establishUnitState(unit)
    local onTile = World.getTile(currentWorld.Tiles, unit.Position.x, unit.Position.y)
    local hasHome = unit.Home
    local hasWork = unit.Work
    local hasTarget = unit.Target
    local hasResource = unit.HeldResource
    local atHome = onTile == hasHome
    local atWork = onTile == hasWork
    local atTarget = onTile == hasTarget
    local atStorage = (onTile.Type == Tile.STORAGE) or (onTile.Type == Tile.KEEP)

    if unit.Health == 0 then
        return UnitState.DEAD, onTile
    elseif hasTarget and not atTarget then
        return UnitState.MOVING, onTile, hasTarget
    elseif unit.Fatigue < MAX_FATIGUE and atWork then
        return UnitState.WORKING, onTile,  hasWork
    elseif hasResource then
        return UnitState.STORING, onTile
    elseif unit.Fatigue > 0 and atHome then
        return UnitState.RESTING, onTile
    else
        return UnitState.IDLE, onTile
    end

end

local unitLabelCons = {}

local function selectUnitOnClick(label, unit)
    local con = unitLabelCons[label]

    if con then
        con:Disconnect()
    end

    unitLabelCons[label] = label.MouseButton1Click:Connect(function()
        ViewSelection.removeInst()
        ClientUtil.unSelectTile()
        ClientUtil.unSelectUnit()
        ViewSelection.addInst(ViewUnit.getInstFromUnit(unit))
        UnitController.SelectUnit(unit)
    end)
end

function ViewSelection.displayTileInfo(tile)

    currentInfoObject = tile

    local container = infoui.Container
    container.Title.Text = Tile.Localisation[tile.Type]

    if tile.OwnerID then
        spawn(function()
            status, err = pcall(function()
                local name = Players:GetNameFromUserIdAsync(tile.OwnerID)
                container.Owner.Label.Text = "Owner: " .. name
                container.Owner.Visible = true
            end)
        end)
    else
        container.Owner.Visible = false
    end

    local villIndex = 1

    if tile.Type == Tile.HOUSE then

        for id, unit in pairs(currentWorld.Units) do

            if unit.Home.Position == tile.Position then
                villagerInfoDisplay[villIndex].Visible = true
                villagerInfoDisplay[villIndex].Label.Text = "Villager: " .. (unit.State and StateLocalisation[unit.State] or "unknown")
                selectUnitOnClick(villagerInfoDisplay[villIndex], unit)
                villIndex = villIndex + 1
                
            end
        end
    end

    for i = villIndex, #villagerInfoDisplay do
        villagerInfoDisplay[i].Visible = false
    end
end 

function ViewSelection.assignWorld(w)
    currentWorld = w 
end

function ViewSelection.removeDisplay()
    Roact.unmount(displayHandle)
end

return ViewSelection