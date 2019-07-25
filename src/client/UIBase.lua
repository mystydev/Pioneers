local UIBase = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ui     = Client.ui
local Roact  = require(game.ReplicatedStorage.Roact)

local Util                = require(Common.Util)
local Tile                = require(Common.Tile)
local UserSettings        = require(Common.UserSettings)
local ViewTile            = require(Client.ViewTile)
local ViewUnit            = require(Client.ViewUnit)
local ViewWorld           = require(Client.ViewWorld)
local ActionHandler       = require(Client.ActionHandler)
local Replication         = require(Client.Replication)
local ClientUtil          = require(Client.ClientUtil)
local StatsPanel          = require(ui.StatsPanel)
local InitiateBuildButton = require(ui.build.InitiateBuildButton)
local BuildList           = require(ui.build.BuildList)
local ObjectInfoPanel     = require(ui.info.ObjectInfoPanel)
local AdminEditor         = require(ui.admin.AdminEditor)
local TesterAlert         = require(Client.ui.TesterAlert)
local NewPlayerPrompt     = require(Client.ui.tutorial.NewPlayerPrompt)
local TutorialPrompt      = require(Client.ui.tutorial.TutorialPrompt)

local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local UIS                 = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")
local RunService          = game:GetService("RunService")

UIBase.State = {}
UIBase.State.MAIN = 1
UIBase.State.BUILD = 2
UIBase.State.TILEBUILD = 3
UIBase.State.INFO = 4
UIBase.State.SELECTWORK = 5

local buildListHandle
local infoHandle
local adminHandle
local promptHandle
local stats
local currentWorld = {}
local highlighted  = {}
local modelUpdates = {}
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
local infoObjectBinding, setInfoObject = Roact.createBinding()

local adminEditorEnabled = false

function UIBase.init(world, displaystats)
    stats = displaystats 
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

function UIBase.highlightModel(model, transparency)

    modelUpdates[model] = RunService.Heartbeat:Connect(function()
        if highlighted[model] then
            highlighted[model]:Destroy()
        end

        local clone = model:Clone()
        highlighted[model] = clone
        clone.Parent = viewport
    end)
end

function UIBase.highlightInst(inst, transparency)
    if inst and not highlighted[inst] then

        if inst:IsA("Model") then
            return UIBase.highlightModel(inst, transparency)
        end

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

function UIBase.highlightInsts(list)
    if list then
        for _, inst in pairs(list) do
            UIBase.highlightInst(inst)
        end
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

    if modelUpdates[inst] then
        modelUpdates[inst]:Disconnect()
        modelUpdates[inst] = nil
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

function UIBase.showStats()
    Roact.mount(Roact.createElement(StatsPanel, {stats = stats}), screengui)
end

function UIBase.showBuildButton()
    Roact.mount(Roact.createElement(InitiateBuildButton, {
        UIBase = UIBase,
    }), screengui)
end

function UIBase.showBuildList()
    buildListHandle = Roact.mount(Roact.createElement(BuildList, {UIBase = UIBase}), screengui)
end

function UIBase.hideBuildList()
    Roact.unmount(buildListHandle)
    buildListHandle = nil
end

function UIBase.exitBuildView()
    if UIState == UIBase.State.BUILD or UIState == UIBase.State.TILEBUILD then
        UIState = UIBase.State.MAIN
        UIBase.hideBuildList()
        UIBase.unHighlightAllInsts()
        UIBase.refocusBackground()
    end
end

function UIBase.transitionToBuildView()
    if UIState == UIBase.State.MAIN then
        UIState = UIBase.State.BUILD
        UIBase.showBuildList()
        UIBase.unfocusBackground()
    end
end

function UIBase.showObjectInfo(object)

    if UIState == UIBase.State.MAIN then
        UIBase.transitionToInfoView()
    end

    UIBase.unHighlightAllInsts()
    UIBase.highlightInst(ViewWorld.convertObjectToInst(object))
    UIBase.highlightInst(ViewWorld.convertObjectToInst(object.Home))
    UIBase.highlightInst(ViewWorld.convertObjectToInst(object.Work))
    UIBase.highlightInsts(ViewUnit.convertIdListToInsts(object.UnitList))

    setInfoObject(object)
end

function UIBase.transitionToInfoView()
    UIState = UIBase.State.INFO
    UIBase.unfocusBackground()
    infoHandle = Roact.mount(Roact.createElement(ObjectInfoPanel, {InfoObject = infoObjectBinding, SetObject = UIBase.showObjectInfo, UIBase = UIBase}), screengui)

    if adminEditorEnabled then
        adminHandle = Roact.mount(Roact.createElement(AdminEditor, {object = infoObjectBinding}), screengui)
    end
end

function UIBase.exitInfoView()
    if UIState == UIBase.State.INFO then
        UIBase.unHighlightAllInsts()
        UIState = UIBase.State.MAIN
        if infoHandle then Roact.unmount(infoHandle) end
        if adminHandle then Roact.unmount(adminHandle) end
        UIBase.refocusBackground()
    end
end

function UIBase.promptSelectWork(workType)
    if UIState == UIBase.State.INFO then
        UIBase.transitionToSelectWorkView()
    end

    UIBase.unHighlightAllInsts()

    if workType == Tile.OTHERPLAYER then
        return UIBase.promptSelectAttack()
    end

    if workType == Tile.GRASS then
        return UIBase.highlightGuardableArea()
    end

    for _, tile in pairs(ViewTile.getPlayerTiles()) do
        if tile.Type == workType and Tile.canAssignWorker(tile) then
            local inst = ViewTile.getInstFromTile(tile)
            UIBase.highlightInst(inst)
            UIBase.listenToInst(inst, function()
                Replication.requestUnitWork(infoObjectBinding:getValue(), tile)
                UIBase.exitSelectWorkView()
            end)
        end
    end
    
end

function UIBase.promptSelectAttack()
    for _, tile in pairs(ViewTile.getOtherPlayerTiles(player.UserId)) do
        local inst = ViewTile.getInstFromTile(tile)
        local clone = UIBase.highlightInst(inst, 0.5)

        if clone then
            UIBase.listenToInst(inst, 
            function()
                Replication.requestUnitAttack(infoObjectBinding:getValue(), tile)
                UIBase.exitSelectWorkView()
            end,
            function() clone.Transparency = 0 end,
            function() clone.Transparency = 0.5 end)
        end
    end
end

function UIBase.transitionToSelectWorkView()
    UIState = UIBase.State.SELECTWORK
end

function UIBase.exitSelectWorkView()
    if UIState == UIBase.State.SELECTWORK or UIState == UIBase.State.INFO then
        UIState = UIBase.State.INFO
        UIBase.exitInfoView()
    end
end

function UIBase.keepPlacementPrompt()
    local playerPos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
    local tiles     = Util.circularCollection(currentWorld.Tiles, playerPos.x, playerPos.y, 0, 10)

    for _, tile in pairs(tiles) do
        UIBase.highlightBuildableTile(tile, Tile.KEEP)
    end
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
    if type == Tile.KEEP then
        return UIBase.keepPlacementPrompt()
    end

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

function UIBase.highlightGuardableTile(tile)
    local inst = ViewTile.getInstFromTile(tile)
    local clone = UIBase.highlightInst(inst, 0.5)

    if clone then
        UIBase.listenToInst(inst,
            function() 
                Replication.requestUnitWork(infoObjectBinding:getValue(), tile)
                UIBase.exitSelectWorkView()
            end, 
            function() clone.Transparency = 0 end,
            function() clone.Transparency = 0.5 end)
    end
end

function UIBase.highlightGuardableArea()
    local tiles = ViewTile.getPlayerTiles()

    for _, tile in pairs(tiles) do
        for _, neighbour in pairs(Util.getNeighbours(currentWorld.Tiles, tile.Position)) do
            if neighbour.Type == Tile.GRASS then
                UIBase.highlightGuardableTile(neighbour)
            end
        end
    end
end

function UIBase.showInDevelopmentWarning(status)
    if UserSettings.shouldShowDevelopmentWarning() then
        UIBase.disableManagedInput()
        TweenService:Create(blur, tweenSlow, {Size = 15}):Play()
        promptHandle = Roact.mount(TesterAlert({
            Approved = status, 
            Clicked = UIBase.dismissDevelopmentWarning,
        }), screengui, "Tester Alert")
    end
end

function UIBase.dismissDevelopmentWarning(showWarning)
    UIBase.dismissPrompt()

    if not showWarning then
        UserSettings.dontShowDeveloptmentWarning()
    end
end

function UIBase.showTutorialPrompt()
    UIBase.waitForPromptDismissal()
    UIBase.disableManagedInput()
    TweenService:Create(blur, tweenSlow, {Size = 15}):Play()
    promptHandle = Roact.mount(Roact.createElement(NewPlayerPrompt, {UIBase = UIBase}), screengui)
end

function UIBase.startTutorial()
    UIBase.dismissPrompt()
    TweenService:Create(blur, tweenSlow, {Size = 15}):Play()
    UIBase.disableManagedInput()
    UIBase.showStats()
    promptHandle = Roact.mount(Roact.createElement(TutorialPrompt, {UIBase = UIBase}), worldgui)
end

function UIBase.dismissPrompt()
    TweenService:Create(blur, tweenSlow, {Size = 0}):Play()

    if promptHandle then
        Roact.unmount(promptHandle)
        promptHandle = nil
    end

    UIBase.enableManagedInput()
end

function UIBase.waitForPromptDismissal()
    repeat
        wait()
    until promptHandle == nil
end

function UIBase.waitForUIState(state)
    repeat
        wait()
    until UIState == state
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

    if UIState == UIBase.State.MAIN or UIState == UIBase.State.INFO then
        local object = ViewWorld.convertInstanceToObject(inst)
        
        if object then
            UIBase.showObjectInfo(object)
        end
    end

    if instEvents[inst] and instEvents[inst].onClick then
        instEvents[inst].onClick()
    end
end

local function mouseRightClicked(input)
    if UIState == UIBase.State.INFO then
        UIBase.exitInfoView()
    elseif UIState == UIBase.State.BUILD or UIState == UIBase.State.TILEBUILD then
        UIBase.exitBuildView()
    elseif UIState == UIBase.State.SELECTWORK then
        UIBase.exitSelectWorkView()
    end
end

local function processInput(input, processed)
    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        mouseMoved(input)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 
            and input.UserInputState == Enum.UserInputState.End then
        mouseClicked(input)
    elseif input.UserInputType == Enum.UserInputType.MouseButton2
            and input.UserInputState == Enum.UserInputState.End then
        mouseRightClicked(input)
    end
end

function UIBase.enableManagedInput()
    beganConnection = UIS.InputBegan:Connect(processInput)
    endedConnection = UIS.InputEnded:Connect(processInput)
    changedConnection = UIS.InputChanged:Connect(processInput)
end

function UIBase.disableManagedInput()
    if beganConnection then
        beganConnection:Disconnect()
        endedConnection:Disconnect()
        changedConnection:Disconnect()
    end
end


return UIBase