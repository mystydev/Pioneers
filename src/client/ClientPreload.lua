local preload = {}
local Client  = script.Parent
local UI      = Client.ui
local Common  = game.ReplicatedStorage.Pioneers.Common
local Assets  = game.ReplicatedStorage.Pioneers.Assets
local Roact   = require(game.ReplicatedStorage.Roact)

local UserSettings = require(Common.UserSettings)
local UIBase       = require(Client.UIBase)
local SoundManager = require(Client.SoundManager)
local LoadingSpinner = require(UI.common.LoadingSpinner)

local RunService      = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")

local preloadList = {
    "rbxassetid://3137132874","rbxassetid://3064453624","rbxassetid://3470337276","rbxassetid://3137922987","rbxassetid://3134625520",
    "rbxassetid://3101321954","rbxassetid://3237279749","rbxassetid://3464265681","rbxassetid://3063768294",
    "rbxassetid://3144305559","rbxassetid://3464265962","rbxassetid://3237284892","rbxassetid://3134628363","rbxassetid://3137132820",
    "rbxassetid://3464266043","rbxassetid://3464218676","rbxassetid://3064039482","rbxassetid://3101321804","rbxassetid://3237284550",
    "rbxassetid://3470339354","rbxassetid://3144305750","rbxassetid://3470332747","rbxassetid://3237282264",
    "rbxassetid://3077212059","rbxassetid://3464282669","rbxassetid://3237281850","rbxassetid://3464265858","rbxassetid://3134625456",
    "rbxassetid://3237282190","rbxassetid://3134625293","rbxassetid://3063804359","rbxassetid://3470339472","rbxassetid://3237279828",
    "rbxassetid://3470337406","rbxassetid://3101321886","rbxassetid://3064453818","rbxassetid://3464269762",
    "rbxassetid://3064056895","rbxassetid://3237282124","rbxassetid://3063744675","rbxassetid://3134633203","rbxassetid://3470354088",
    "rbxassetid://3470332877","rbxassetid://3470327868","rbxassetid://3237288852","rbxassetid://3470333132","rbxassetid://3470328252",
    "rbxassetid://3470328143","rbxassetid://3470333280","rbxassetid://3470333025","rbxassetid://3470339219","rbxassetid://3470770300",
    "rbxassetid://3465608887","rbxassetid://3101322014","rbxassetid://3064053551","rbxassetid://3134625173","rbxassetid://3064453876",
    "rbxassetid://3464270025","rbxassetid://3464274359","rbxassetid://3237284465","rbxassetid://3464269865","rbxassetid://3464265775",
    "rbxassetid://3144182791","rbxassetid://3064009593","rbxassetid://3137569139",
    "rbxassetid://3134628736","rbxassetid://3237284972","rbxassetid://3144182667","rbxassetid://3064039535","rbxassetid://3137891616",
    "rbxassetid://3237281781","rbxassetid://3470328016","rbxassetid://3464269947","rbxassetid://3137923052","rbxassetid://3144305681",
    "rbxassetid://3080817017","rbxassetid://3242019037","rbxassetid://3144305819","rbxassetid://3077218297",
    "rbxassetid://3064039406","rbxassetid://3064022555","rbxassetid://3077211985","rbxassetid://3470328336", "rbxassetid://3569229445",
    "rbxassetid://4364737957","rbxassetid://4312670626","rbxassetid://4298535124",
    }

local loading = true
local loadingGui

local tweenInfo  = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fastTween  = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local midTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local spinnerTween = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)

preload.Loaded = false

local assetsLoaded = false
local currentText = ""
local spinnerHandle

local lock
local queued = {}
local queuelength = 0

local infos = {}
local sequentialInfos = {}
local infoPosIndex = 0

local function createText()
    local element = Instance.new("TextLabel")
    element.BackgroundTransparency = 1
    element.TextColor3 = Color3.new(1,1,1)
    element.Font = "SourceSans"
    element.TextSize = 24
    element.AnchorPoint = Vector2.new(0.5, 0.5)
    element.Position = UDim2.new(0.5, 0, 0.6, 0)
    element.TextTransparency = 1
    element.Parent = loadingGui
    --element.TextXAlignment = "Left"

    sequentialInfos[infoPosIndex] = element
    
    coroutine.wrap(function()
        for i = 0, infoPosIndex-1 do
            --wait(0.1)
            TweenService:Create(sequentialInfos[i], midTween, {Position = UDim2.new(0.5, 0, 0.6, (infoPosIndex - i) * 30)}):Play()
        end
    end)()

    infoPosIndex = infoPosIndex + 1

    return element
end

local function deleteTexts()
    for i, v in pairs(infos) do
        v:Destroy()
        infos[i] = nil
    end

    infoPosIndex = 0
end

local function updateInfo(index, text)
    coroutine.wrap(function()

        local element = infos[index]

        if not element then
            element = createText()
            infos[index] = element
            element.Text = text
            --wait(infoPosIndex / 20)
            wait(0.5)
            if preload.FullyLoaded  then return end
            TweenService:Create(element, tweenInfo, {TextTransparency = 0}):Play()
        else
            TweenService:Create(element, midTween, {TextTransparency = 1}):Play()
            wait(0.2)
            if preload.FullyLoaded then return end
            element.Text = text
            TweenService:Create(element, midTween, {TextTransparency = 0}):Play()
        end
    end)()
end

--[[local function updateInfo(text, loadedOverride, queueOverride)
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
end]]--

--show update then return to previous text
local function smallUpdateInfo(text, override)

    local t = loadingGui.Info.Text
    updateInfo(text)
    updateInfo(t, false, true)
end

_G.updateLoadStatus = updateInfo --Yes this will be changed

local function load()
    loadingGui = Assets.LoadingGui:Clone()
    loadingGui.Spinner:Destroy()
    loadingGui.Parent = game.Players.LocalPlayer.PlayerGui
    game.Lighting.LoadingBlur.Size = 56
    loadingGui.Info.TextColor3 = Color3.fromRGB(255, 255, 255)
    workspace.CurrentCamera.CFrame = CFrame.new(Vector3.new(30, 60, 120))

    spinnerHandle = Roact.mount(Roact.createElement(LoadingSpinner), loadingGui)

    spawn(function()
        updateInfo("Assets", "⭕Loading assets...")
        ContentProvider:PreloadAsync({Assets.Preload})

        repeat 
            wait() 
        until ContentProvider.RequestQueueSize > 0
        
        updateInfo("Assets", "✅Assets loaded")
        assetsLoaded = true
    end)

    TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 0}):Play()
    --TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 0.25}):Play()
    --TweenService:Create(loadingGui.Spinner, spinnerTween, {Rotation = 360}):Play()
    
    wait(10)

    if not preload.Loaded then
        updateInfo("Long", "❗Looks like something is taking a while...")
    end
        
    wait(10)

    preload.Aborting = true

    if not preload.Loaded then
        --TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
        --TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 1}):Play()
    end
    
    wait(0.5)

    if not preload.Loaded then
        loadingGui.Info.Text = "❗Client failed to load, retrying..."
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

            updateInfo("Ready", "🔆Ready")

            wait(1)
            
            deleteTexts()
            SoundManager.transition()
            preload.FullyLoaded = true
            spawn(function() Roact.unmount(spinnerHandle) end)
            --TweenService:Create(loadingGui.Spinner, fastTween, {ImageTransparency = 1}):Play()
            TweenService:Create(loadingGui.Background, tweenInfo, {BackgroundTransparency = 1}):Play()
            TweenService:Create(loadingGui.Info, fastTween, {TextTransparency = 1}):Play()
            TweenService:Create(game.Lighting.LoadingBlur, tweenInfo, {Size = 0}):Play()
            wait(1)

            loadingGui.Info.Text = ""
            
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
            UIBase.showInDevelopmentWarning()
        end
    end)
end

return preload