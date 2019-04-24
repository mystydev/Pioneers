local preload = {}

local RunService      = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")

local loading = true
local loadingGui

local tweenInfo  = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fastTween  = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local spinnerTween = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)

preload.Loaded = false

local assetsLoaded = false
local currentText = ""

local function updateInfo(text, override)
    if not preload.Aborting then
        if override then
            TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
            wait(0.4)
        end

        if not preload.Loaded or override then
            loadingGui.Info.Text = text
            TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 0}):Play()
        end
    end
end

--show update then return to previous text
local function smallUpdateInfo(text)
    if preload.Loaded then
        return end

    local t = loadingGui.Info.Text
    TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
    wait(0.5)
    updateInfo(text)
    wait(0.5)

    if preload.Loaded then
        return end

    TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
    wait(0.5)
    updateInfo(t)
end

_G.updateLoadStatus = updateInfo

local function load()
    loadingGui = game.StarterGui.LoadingGui:Clone()
    loadingGui.Parent = game.Players.LocalPlayer.PlayerGui
    game.Lighting.LoadingBlur.Size = 56
    loadingGui.Info.TextColor3 = Color3.fromRGB(255, 255, 255)
    workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(30, 60, 120))

    spawn(function()
        ContentProvider:PreloadAsync(game.ReplicatedStorage.Pioneers.Assets:GetChildren())
        assetsLoaded = true
        smallUpdateInfo("Assets loaded...")
    end)

    TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 0}):Play()
    TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 0.25}):Play()
    TweenService:Create(loadingGui.Spinner, spinnerTween, {Rotation = 360}):Play()
    
    wait(5)

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
    if not preload.Aborting then
        preload.Loaded = true

        spawn(function()
            updateInfo("Let's go!", true)

            wait(1)

            TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 1}):Play()
            TweenService:Create(loadingGui.Background, tweenInfo, {BackgroundTransparency = 1}):Play()
            TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
            TweenService:Create(game.Lighting.LoadingBlur, tweenInfo, {Size = 0}):Play()

            wait(2)
            
            loadingGui:Destroy()
            game.Lighting.LoadingBlur.Size = 0
        end)
    end
end


function preload.init()
    game.ReplicatedFirst:RemoveDefaultLoadingScreen()
    spawn(load)
end

return preload