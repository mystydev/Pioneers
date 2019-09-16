local function start()
    
    local Client = script
    local Common = game.ReplicatedStorage.Pioneers.Common

    local ClientPreload = require(Client.ClientPreload)
    ClientPreload.init()
    
    local ActionHandler   = require(Client.ActionHandler)
    local ViewWorld       = require(Client.ViewWorld)
    local UIBase          = require(Client.UIBase)
    Replication           = require(Client.Replication)
    local SoundManager    = require(Client.SoundManager)
    local NightCycle      = require(Client.Nightcycle)
    local World           = require(Common.World)
    local UserSettings    = require(Common.UserSettings)

    print("Pioneers client waiting for server to be ready")
    local status

    repeat 
        wait() 
        status = Replication.ready()
    until status ~= nil

    print("Pioneers client starting...")
    
    SoundManager.init()
    world = World.new()

    Replication.init(world, UIBase)
    ViewWorld.displayWorld(world)

    local stats = Replication.getUserStats()
    Replication.getUserSettings()

    ClientPreload.tellReady()

    ActionHandler.init(world)
    UIBase.init(world, stats)

    UIBase.showInDevelopmentWarning(status)

    if not UserSettings.hasDoneTutorial() then
        UIBase.showTutorialPrompt()
    end

    UIBase.waitForPromptDismissal()
    UIBase.showStats()
    UIBase.showLocation()
    --UIBase.showChatBox()
    UIBase.showFeedbackButton()
    --UIBase.showFindKingdomButton()
    UIBase.showBuildButton()
end

local LogService = game:GetService("LogService")

LogService.MessageOut:Connect(function(message, type)
    if string.find(message, "Pion unrecoverable") then
        print("Pioneers client experienced an unrecoverable error... Automatically restarting!")

        Replication.worldDied()

        for i, v in pairs(workspace:GetChildren()) do
            if (v:IsA("BasePart") or v:IsA("Model") or v:IsA("SoundGroup")) and v.Name ~= "Terrain" then
                v:Destroy()
            end
        end

        if world then
            world.Tiles = {}
            world.Units = {}
            world.Dead = true
        end

        if game.Lighting:FindFirstChild("Blur") then
            game.Lighting.Blur:Destroy()
        end

        script:Clone().Parent = script.Parent
        script:Destroy()
    end
end)

local resetBindable = Instance.new("BindableEvent")
resetBindable.Event:connect(function()
    error("Pion unrecoverable - User initiated reset")
end)

spawn(function()
    while not pcall(function() game.StarterGui:SetCore("ResetButtonCallback", resetBindable) end) do
        wait()
    end
end)

start()

