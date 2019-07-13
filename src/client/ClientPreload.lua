local preload = {}
local Client  = script.Parent
local Common  = game.ReplicatedStorage.Pioneers.Common
local Roact   = require(game.ReplicatedStorage.Roact)

local UserSettings = require(Common.UserSettings)
local TesterAlert  = require(Client.ui.TesterAlert)

local RunService      = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")

local loading = true
local loadingGui

local tweenInfo  = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fastTween  = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local spinnerTween = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)

preload.Loaded = false

local assetsLoaded = false
local currentText = ""

local lock
local queued = {}
local queuelength = 0
local function updateInfo(text, loadedOverride, queueOverride)
    spawn(function()

        if queued[text] and not queueOverride then 
            return end

        if not queueOverride then 
            queuelength = queuelength + 1 
        end

        queued[text] = true

        while lock do
            wait()
        end

        if not queueOverride then 
            queuelength = queuelength - 1 
        end

        if not preload.Loaded or loadedOverride then
            lock = true
            
            if not preload.Aborting then

                TweenService:Create(loadingGui.Info, queuelength == 0 and infoTween or fastTween, {TextTransparency = 1}):Play()
                wait(queuelength == 0 and 0.5 or 0.1)
                loadingGui.Info.Text = text
                TweenService:Create(loadingGui.Info, queuelength == 0 and infoTween or fastTween, {TextTransparency = 0}):Play()
                wait(queuelength == 0 and 0.5 or 0.1)
                
            end

            lock = false
        end
    end)
end

--show update then return to previous text
local function smallUpdateInfo(text, override)

    local t = loadingGui.Info.Text
    updateInfo(text)
    updateInfo(t, false, true)
end

_G.updateLoadStatus = updateInfo --Yes this will be changed

local function load()
    loadingGui = game.StarterGui.LoadingGui:Clone()
    loadingGui.Parent = game.Players.LocalPlayer.PlayerGui
    game.Lighting.LoadingBlur.Size = 56
    loadingGui.Info.TextColor3 = Color3.fromRGB(255, 255, 255)
    workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(30, 60, 120))

    spawn(function()
        ContentProvider:PreloadAsync(game.ReplicatedStorage.Pioneers.Assets:GetChildren())
        smallUpdateInfo("Assets loaded", true)
        assetsLoaded = true
    end)

    TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 0}):Play()
    TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 0.25}):Play()
    TweenService:Create(loadingGui.Spinner, spinnerTween, {Rotation = 360}):Play()
    
    wait(10)

    if not preload.Loaded then
        updateInfo("Looks like something is taking a while...", true)
    end
        
    wait(10)

    preload.Aborting = true

    if not preload.Loaded then
        TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
        TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 1}):Play()
    end
    
    wait(0.5)

    if not preload.Loaded then
        loadingGui.Info.Text = "Client failed to load, retrying..."
        loadingGui.Info.TextColor3 = Color3.fromRGB(218, 40, 43)
        TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 0}):Play()
        wait(1.5)
        TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
        loadingGui:Destroy()
        error("Pion unrecoverable - Client failed to load")
    end
end



function preload.tellReady()
    if not preload.Aborting and not preload.Loaded then
        preload.Loaded = true

        spawn(function()
            repeat wait() until assetsLoaded and queuelength == 0

            if preload.Aborting then
                return end

            updateInfo("Ready", true)

            

            wait(1)

            preload.FullyLoaded = true
            TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 1}):Play()
            TweenService:Create(loadingGui.Background, tweenInfo, {BackgroundTransparency = 1}):Play()
            TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
            TweenService:Create(game.Lighting.LoadingBlur, tweenInfo, {Size = 0}):Play()

            --wait(2)
            
            --loadingGui:Destroy()
            --game.Lighting.LoadingBlur.Size = 0
        end)
    end
end


function preload.init()
    game.ReplicatedFirst:RemoveDefaultLoadingScreen()
    spawn(load)
end

function preload.displayTesterStatus(status)
    spawn(function()
        if status == false then
            preload.Loaded = true
            preload.Aborting = true

            TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 1}):Play()
            TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
            TweenService:Create(loadingGui.Background, tweenInfo, {BackgroundTransparency = 0}):Play()
            Roact.mount(TesterAlert({Approved = status}), loadingGui, "Tester Alert")
            wait(10)

            game.Players.LocalPlayer:Kick("Not an approved tester.")

        elseif status == true then
        
            repeat wait() until preload.FullyLoaded

            local handle

            local function onAgree(showWarning)
                TweenService:Create(game.Lighting.LoadingBlur, tweenInfo, {Size = 0}):Play()
                if handle then
                    Roact.unmount(handle)
                end
                
                if not showWarning then
                    UserSettings.dontShowDeveloptmentWarning()
                end
            end

            TweenService:Create(game.Lighting.LoadingBlur, tweenInfo, {Size = 15}):Play()

            if UserSettings.shouldShowDevelopmentWarning() then
                handle = Roact.mount(TesterAlert({Approved = status, Clicked = onAgree}), loadingGui, "Tester Alert")
            else
                onAgree()
            end
        end
    end)
end

return preload