local UIBase = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Assets = game.ReplicatedStorage.Pioneers.Assets
local ui     = Client.ui
local Roact  = require(game.ReplicatedStorage.Roact)

local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local UIS                 = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")
local RunService          = game:GetService("RunService")
local StarterGui          = game:GetService("StarterGui")

UIBase.State = {}
UIBase.State.MAIN = 1
UIBase.State.BUILD = 2
UIBase.State.TILEBUILD = 3
UIBase.State.INFO = 4
UIBase.State.SELECTWORK = 5
UIBase.State.FEEDBACK = 6
UIBase.State.FINDKINGDOM = 7
UIBase.State.UNITCONTROL = 8

local buildButtonHandle
local buildListHandle
local infoHandle
local adminHandle
local promptHandle
local combatHandle
local updateHandle
local feedbackHandle
local findKingdomHandle
local partitionViewHandle
local loadingHandle
local progressionHandle
local unitControlButtonHandle
local stats
local statsBinding, setStats = Roact.createBinding()
local currentWorld = {}
local highlighted  = {}
local modelUpdates = {}
local instChanges  = {}
local instEvents   = {}
local healthBars   = {}
local tileMarkers  = {}
local UIState      = UIBase.State.MAIN
local player       = Players.LocalPlayer
local worldgui     = Instance.new("ScreenGui", player.PlayerGui)
local screengui    = Instance.new("ScreenGui", player.PlayerGui)
local viewport     = Instance.new("ViewportFrame", worldgui)
local blur         = Instance.new("BlurEffect")
local placementHighlight = Assets.Grass:Clone()
local vignette     = StarterGui.Vignette:Clone()
local desaturate   = Lighting.BaseCorrection
local tweenSlow    = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenFast    = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local infoObjectBinding, setInfoObject = Roact.createBinding()
local updatingBinding, setUpdating = Roact.createBinding(false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
player.PlayerGui:SetTopbarTransparency(1)

local adminEditorEnabled = false

function UIBase.init(world, displaystats)
    stats = displaystats 
    currentWorld = world
    worldgui.Name = "World UI"
    worldgui.IgnoreGuiInset = true
    worldgui.ResetOnSpawn = false
    screengui.Name = "Screen UI"
    screengui.IgnoreGuiInset = true
    screengui.DisplayOrder = 2
    screengui.ResetOnSpawn = false
    blur.Size = 0
    blur.Parent = Lighting
    desaturate.Saturation = 0
    desaturate.Parent = Lighting
    vignette.Parent = screengui
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.Position = UDim2.new(0, 0, 0, 0)
    viewport.BackgroundTransparency = 1
    viewport.CurrentCamera = workspace.CurrentCamera
    viewport.Ambient = Color3.new(1, 1, 1)
    viewport.LightColor = Color3.new(1, 1, 1)
    viewport.LightDirection = Vector3.new(0, -1, 0)

    Util                = require(Common.Util)
    Tile                = require(Common.Tile)
    UserSettings        = require(Common.UserSettings)
    UserStats           = require(Common.UserStats)
    World               = require(Common.World)
    ViewTile            = require(Client.ViewTile)
    ViewUnit            = require(Client.ViewUnit)
    ViewWorld           = require(Client.ViewWorld)
    ActionHandler       = require(Client.ActionHandler)
    Replication         = require(Client.Replication)
    ClientUtil          = require(Client.ClientUtil)
    SoundManager        = require(Client.SoundManager)
    UnitControl         = require(Client.UnitControl)
    StatsPanel          = require(ui.StatsPanel)
    InitiateBuildButton = require(ui.build.InitiateBuildButton)
    BuildList           = require(ui.build.BuildList)
    ObjectInfoPanel     = require(ui.info.ObjectInfoPanel)
    WorldLocation       = require(ui.info.WorldLocation)
    AdminEditor         = require(ui.admin.AdminEditor)
    HealthBar           = require(ui.world.HealthBar)
    TileMarker          = require(ui.world.TileMarker)
    TesterAlert         = require(ui.TesterAlert)
    NewPlayerPrompt     = require(ui.tutorial.NewPlayerPrompt)
    TutorialPrompt      = require(ui.tutorial.TutorialPrompt)
    CombatWarning       = require(ui.common.CombatWarning)
    UpdateAlert         = require(ui.common.UpdateAlert)
    DefaultPrompt       = require(ui.common.DefaultPrompt)
    LoadingSpinner      = require(ui.common.LoadingSpinner)
    ChatBox             = require(ui.chat.ChatBox)
    FeedbackButton      = require(ui.feedback.FeedbackButton)
    FeedbackForm        = require(ui.feedback.FeedbackForm)
    FeedbackSubmitted   = require(ui.feedback.FeedbackSubmitted)
    FindKingdomButton   = require(ui.teleport.FindKingdomButton)
    FindKingdom         = require(ui.teleport.FindKingdom)
    PartitionView       = require(ui.partitionOverview.PartitionView)
    CurrentLevelDisplay = require(ui.progression.CurrentLevelDisplay)
    UnitSpots           = require(ui.unitControl.UnitSpots)
    InitiateControlButton = require(ui.unitControl.InitiateControlButton)

    placementHighlight.CFrame = CFrame.new(0,math.huge,0)
    gameSettings = Replication.getGameSettings()
end

function UIBase.highlightCharacter()
    player.Character.Archivable = true
    player.Character.Sound.LocalSound.Disabled = true
    player.Character.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    UIBase.highlightModel(player.Character)
end

function UIBase.unfocusBackground(blurVal, saturation)
    blurVal = blurVal or 20
    saturation = saturation or -0.5

    SoundManager.pullFocus()
    TweenService:Create(blur, tweenSlow, {Size = blurVal}):Play()
    TweenService:Create(desaturate, tweenSlow, {Saturation = saturation}):Play()
    --UIBase.highlightCharacter()
end

function UIBase.refocusBackground()
    SoundManager.endFocus()
    TweenService:Create(blur, tweenSlow, {Size = 0}):Play()
    TweenService:Create(desaturate, tweenFast, {Saturation = 0}):Play()
    UIBase.unHighlightAllInsts()
end

function UIBase.highlightModel(model, transparency)
    if not modelUpdates[model] then
        modelUpdates[model] = RunService.Heartbeat:Connect(function()
            if highlighted[model] then
                highlighted[model]:Destroy()
            end

            local clone = model:Clone()
            highlighted[model] = clone
            clone.Parent = viewport
        end)
    end
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

function UIBase.showLocation()
    Roact.mount(Roact.createElement(WorldLocation), screengui)
end

function UIBase.showChatBox()
    Roact.mount(Roact.createElement(ChatBox, {UIBase = UIBase}), screengui)
end

function UIBase.showFeedbackButton()
    Roact.mount(Roact.createElement(FeedbackButton, {UIBase = UIBase}), screengui)
end

function UIBase.showFindKingdomButton()
    Roact.mount(Roact.createElement(FindKingdomButton, {UIBase = UIBase}), screengui)
end

function UIBase.showBuildButton()
    buildButtonHandle = Roact.mount(Roact.createElement(InitiateBuildButton, {
        UIBase = UIBase,
    }), screengui)
end

function UIBase.hideBuildButton()
    if buildButtonHandle then
        Roact.unmount(buildButtonHandle)
        buildButtonHandle = false
    end
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
        placementHighlight.CFrame = CFrame.new(0,math.huge,0)
        UIState = UIBase.State.MAIN
        UIBase.hideBuildList()
        UIBase.refocusBackground()
        UIBase.unmountTileMarkers()

        if unitControlButtonHandle ~= nil then
            UIBase.showUnitControlButton()
        end
    end
end

function UIBase.transitionToBuildView()
    if UIState == UIBase.State.MAIN then
        UIState = UIBase.State.BUILD
        UIBase.showBuildList()
        UIBase.unfocusBackground()
        UIBase.hideUnitControlButton()
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
    SoundManager.softSelect()
    ActionHandler.provideUnitChangeHook(function() UIBase.showObjectInfo(object) end)
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
        UIState = UIBase.State.MAIN
        if infoHandle then Roact.unmount(infoHandle) end
        if adminHandle then Roact.unmount(adminHandle) end
        UIBase.refocusBackground()
    end
end

function UIBase.promptSelectWork(workType, unitpos) --unitpos is a military units position
    if UIState == UIBase.State.INFO then
        UIBase.transitionToSelectWorkView()
    end

    UIBase.unmountTileMarkers()
    UIBase.unHighlightAllInsts()
    --UIBase.highlightModel(player.Character)

    if workType == Tile.OTHERPLAYER then
        return UIBase.promptSelectAttack()
    end

    if workType == Tile.GRASS then
        return UIBase.highlightGuardableArea(unitpos)
    end

    for _, tile in pairs(ViewTile.getPlayerTiles()) do
        if tile.Type == workType then
        
            local canAssign = World.canAssignWorker(Replication.getTiles(), tile, gameSettings.MAX_STORAGE_DIST)

            if canAssign == false  then
                UIBase.displayTileMarker(tile, UIBase.TileMarker.NOSTORAGE)
            elseif canAssign then
                local inst = ViewTile.getInstFromTile(tile)
                UIBase.highlightInst(inst)
                UIBase.listenToInst(inst, function()
                    Replication.requestUnitWork(infoObjectBinding:getValue(), tile)
                    UIBase.exitSelectWorkView()
                end)
            end
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
        UIBase.unmountTileMarkers()
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
    --UIBase.highlightModel(player.Character)

    if UIState == UIBase.State.MAIN then
        return end
        
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

    local partitionOwner = Replication.getCachedPartitionOwner(tile.Position.x, tile.Position.y)
    if partitionOwner and tonumber(partitionOwner) ~= player.UserId then
        UIBase.displayTileMarker(tile, UIBase.TileMarker.NOOWNERSHIP)
        return
    end

    local clone = UIBase.highlightInst(inst, 0.5)

    local stats = Replication.getUserStats()
    local req = Tile.ConstructionCosts[type]

    local storage, distance = World.getClosestStorageToTile(Replication.getTiles(), tile.Position)

    if distance > gameSettings.MAX_STORAGE_DIST then
        UIBase.displayTileMarker(tile, UIBase.TileMarker.NOSTORAGE)
    end

    if clone then
        placementHighlight.Parent = clone.Parent
        
        UIBase.listenToInst(inst,
            function()
                placementHighlight.CFrame = CFrame.new(0,math.huge,0)
                if UserStats.hasEnoughResources(stats, req) then
                    ActionHandler.attemptBuild(tile, type)
                end

                if UserStats.hasEnoughResources(stats, req) then
                    UIBase.highlightType(type, true)
                else
                    UIBase.exitBuildView()
                end
            end, 
            function() 
                placementHighlight.CFrame = clone.CFrame
            end,
            function() 
                placementHighlight.CFrame = CFrame.new(0,math.huge,0)
            end)
    end
end

function UIBase.highlightBuildableArea(type)
   
    UIBase.unmountTileMarkers()

    if type == Tile.KEEP then
        return UIBase.keepPlacementPrompt()
    end

    local tiles = ViewTile.getPlayerTiles()

    for _, tile in pairs(tiles) do
        if Tile.isWalkable(tile) then
            for _, neighbour in pairs(World.getNeighbours(currentWorld.Tiles, tile.Position)) do
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

function UIBase.highlightGuardableArea(pos)
    local tiles = ViewTile.getPlayerTiles()

    for _, tile in pairs(tiles) do
        for _, neighbour in pairs(World.getNeighbours(currentWorld.Tiles, tile.Position)) do
            if neighbour.Type == Tile.GRASS and (not tile.UnitList or #tile.UnitList == 0) then
                UIBase.highlightGuardableTile(neighbour)
            end
        end
    end

    local unitTiles = Util.circularCollection(currentWorld.Tiles, pos.x, pos.y, 0, 10)

    for _, tile in pairs(unitTiles) do
        if tile.Type == Tile.GRASS and (not tile.UnitList or #tile.UnitList == 0) then
            UIBase.highlightGuardableTile(tile)
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
    SoundManager.alert()
end

function UIBase.startTutorial()
    UIBase.dismissPrompt()
    TweenService:Create(blur, tweenSlow, {Size = 15}):Play()
    UIBase.disableManagedInput()
    UIBase.showStats()
    promptHandle = Roact.mount(Roact.createElement(TutorialPrompt, {UIBase = UIBase}), worldgui)
end

function UIBase.endTutorial()
    UIBase.dismissPrompt()
end

function UIBase.dismissPrompt()
    UIBase.refocusBackground()

    if promptHandle then
        coroutine.wrap(function() Roact.unmount(promptHandle) end)()
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

function UIBase.displayObjectHealth(object)
    if not healthBars[object] then
        healthBars[object] = Roact.mount(Roact.createElement(HealthBar, {object = object}), screengui)
    end
end

function UIBase.combatAlert()
    if not combatHandle then
        SoundManager.urgentAlert()
        TweenService:Create(vignette, tweenSlow, {ImageColor3 = Color3.new(0.8, 0.15, 0.15)}):Play()
        combatHandle = Roact.mount(Roact.createElement(CombatWarning), screengui)
    end 
end

function UIBase.endCombatAlert()
    TweenService:Create(vignette, tweenSlow, {ImageColor3 = Color3.new(0, 0, 0)}):Play()
    if combatHandle then 
        Roact.unmount(combatHandle) 
        combatHandle = nil
    end
end 

function UIBase.updateAlert()
    if not updateHandle then
        SoundManager.urgentAlert()
        setUpdating(true)
        updateHandle = Roact.mount(Roact.createElement(UpdateAlert, {updating = updatingBinding}), screengui)
    end
end

function UIBase.endUpdateAlert()
    if updateHandle and updatingBinding:getValue() then
        setUpdating(false)
        delay(5, function()
            Roact.unmount(updateHandle)
            updateHandle = nil
        end)
    end
end

function UIBase.chatFocused()
    _G.FreecamDisabled = true
    UIBase.disableManagedInput()
end

function UIBase.chatUnfocused()
    _G.FreecamDisabled = false
    delay(0.1, UIBase.enableManagedInput) --Prevent clicking to get away from chat from interacting
end

function UIBase.transitionToFeedbackView()
    if UIState == UIBase.State.MAIN then
        _G.FreecamDisabled = true
        UIState = UIBase.State.FEEDBACK
        feedbackHandle = Roact.mount(Roact.createElement(FeedbackForm, {UIBase = UIBase}), screengui)
        UIBase.unfocusBackground()
    end
end

function UIBase.exitFeedbackView()
    if UIState == UIBase.State.FEEDBACK then
        _G.FreecamDisabled = false
        UIState = UIBase.State.MAIN
        Roact.unmount(feedbackHandle)
        UIBase.refocusBackground()
    end
end

function UIBase.showFeedbackForm()
    UIBase.transitionToFeedbackView()
end

function UIBase.submittedFeedback()
    Roact.unmount(feedbackHandle)
    feedbackHandle = Roact.mount(Roact.createElement(FeedbackSubmitted, {UIBase = UIBase}), screengui)
    wait(4)
    UIBase.exitFeedbackView()
end

function UIBase.transitionToFindKingdomView()
    if UIState == UIBase.State.MAIN then
        _G.FreecamDisabled = true
        UIState = UIBase.State.FINDKINGDOM
        findKingdomHandle = Roact.mount(Roact.createElement(FindKingdom, {UIBase = UIBase}), screengui)
        UIBase.unfocusBackground()
    end
end

function UIBase.exitFindKingdomView()
    if UIState == UIBase.State.FINDKINGDOM then
        _G.FreecamDisabled = false
        UIState = UIBase.State.MAIN
        Roact.unmount(findKingdomHandle)
        UIBase.refocusBackground()
    end
end

function UIBase.showFindKingdom()
    UIBase.transitionToFindKingdomView()
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

local function keyPressed(input)
    if input.UserInputState == Enum.UserInputState.End and input.KeyCode == Enum.KeyCode.P then
        UIBase.toggleUnitControlSpots()
    end
end

local lastRightDown = tick()
local function processInput(input, processed)
    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        mouseMoved(input)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 
            and input.UserInputState == Enum.UserInputState.End then
        mouseClicked(input)
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if input.UserInputState == Enum.UserInputState.End and tick() - lastRightDown < 0.2 then
            mouseRightClicked(input)
        end

        lastRightDown = tick()
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        keyPressed(input)
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

function UIBase.displayPartitionOverview()
    UIBase.disableManagedInput()
    partitionViewHandle = Roact.mount(Roact.createElement(PartitionView, {UIBase = UIBase}), screengui)
end

function UIBase.hidePartitionOverview()
    coroutine.wrap(function() Roact.unmount(partitionViewHandle) end)()
    partitionViewHandle = nil
end

function UIBase.waitForPartitionOverviewDismissal()
    repeat
        wait()
    until partitionViewHandle == nil
end

function UIBase.yesNoPrompt(title, message)

    UIBase.waitForPromptDismissal()
    UIBase.unfocusBackground()
    UIBase.disableManagedInput()

    local clickedYes = false

    if not promptHandle then

        promptHandle = Roact.mount(Roact.createElement(DefaultPrompt, {
            Title = title,
            Text = message,
            Buttons = {
                {Text = "Yes", Color = Color3.fromRGB(124, 179, 66), Event = function() clickedYes = true UIBase.dismissPrompt() end},
                {Text = "No", Color = Color3.fromRGB(229, 57, 53), Event = function() UIBase.dismissPrompt() end},
            }
        }), screengui)

    end

    SoundManager.menuPopup()

    UIBase.waitForPromptDismissal()
    return clickedYes
end

--choices = {{Text = "...", Color = ...}, {Text=....}}
function UIBase.choicePrompt(title, message, choices, props)

    UIBase.waitForPromptDismissal()
    UIBase.unfocusBackground()
    UIBase.disableManagedInput()

    local clicked = 0

    if not promptHandle then

        local buttons = {}

        for i, v in pairs(choices) do
            buttons[i] = {
                Text = v.Text,
                Color = v.Color,
                Event = function() clicked = i if not v.Disabled then UIBase.dismissPrompt() end end,
            }
        end
        
        props = props or {}
        props.Title = title
        props.Text = message
        props.Buttons = buttons

        promptHandle = Roact.mount(Roact.createElement(DefaultPrompt, props), screengui)

    end

    SoundManager.menuPopup()

    UIBase.waitForPromptDismissal()
    return clicked
end

function UIBase.displayInfoPrompt(title, message)

    infoPrompt = Roact.mount(Roact.createElement(DefaultPrompt, {
        Title = title,
        Text = message,
        Position = UDim2.new(0, 200, 0, 150),
        Size = UDim2.new(0, 400, 0, 300),
    }), screengui)
end

function UIBase.blockingLoadingScreen(message)
    UIBase.unfocusBackground()
    UIBase.disableManagedInput()

    loadingHandle = Roact.mount(Roact.createElement(LoadingSpinner, {
        vignette = true,
        message = message,
    }), screengui)
end

function UIBase.removeLoadingScreen()
    if loadingHandle then
        SoundManager.transition()
        UIBase.refocusBackground()
        UIBase.enableManagedInput()
        coroutine.wrap(function() Roact.unmount(loadingHandle) end)()
        loadingHandle = nil
    end
end

function UIBase.showProgressionUI(stats)
    local progressionHandle = Roact.mount(Roact.createElement(CurrentLevelDisplay, {
        stats = stats,
    }), screengui)
end

function UIBase.hideProgressionUI()
    if progressionHandle then
        Roact.unmount(progressionHandle)
        progressionHandle = nil
    end
end

UIBase.TileMarker = {}
UIBase.TileMarker.NOSTORAGE = 1
UIBase.TileMarker.NOOWNERSHIP = 2

TileMarkerIcons = {}
TileMarkerIcons[UIBase.TileMarker.NOSTORAGE] = "rbxassetid://4486323066"
TileMarkerIcons[UIBase.TileMarker.NOOWNERSHIP] = "rbxassetid://3616348293"

function UIBase.displayTileMarker(tile, markerType)
    local inst, updateInst = Roact.createBinding(ViewTile.getInstFromTile(tile))

    if not tileMarkers[tile] then
        tileMarkers[tile] = Roact.mount(Roact.createElement(TileMarker, {
            inst = inst,
            imageId = TileMarkerIcons[markerType]
        }), screengui)
    end
end

function UIBase.unmountTileMarkers()
    for tile, marker in pairs(tileMarkers) do
        Roact.unmount(marker)
        tileMarkers[tile] = nil
    end
end

function UIBase.displayUnitControlSpots()
    if UIState == UIBase.State.MAIN then
        UIBase.unfocusBackground(6, -0.7)
        if not controlSpots then
            UnitControl.evalLocalArea()
            controlSpots = Roact.mount(Roact.createElement(UnitSpots), screengui)
        end

        UIBase.hideBuildButton()
        UIState = UIBase.State.UNITCONTROL
    end
end

function UIBase.unmountUnitControlSpots()
    if UIState == UIBase.State.UNITCONTROL then
        UIBase.refocusBackground()
        if controlSpots then
            Roact.unmount(controlSpots)
            controlSpots = nil
        end

        if buildButtonHandle ~= nil then
            UIBase.showBuildButton()
        end

        UIState = UIBase.State.MAIN
    end
end

function UIBase.toggleUnitControlSpots()
    if not controlSpots then
        UIBase.displayUnitControlSpots()
    else
        UIBase.unmountUnitControlSpots()
    end
end

function UIBase.showUnitControlButton()
    unitControlButtonHandle = Roact.mount(Roact.createElement(InitiateControlButton, {
        UIBase = UIBase,
    }), screengui)
end

function UIBase.hideUnitControlButton()
    if unitControlButtonHandle then
        Roact.unmount(unitControlButtonHandle)
        unitControlButtonHandle = false
    end
end

return UIBase