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
    local Util            = require(Common.Util)

    local Players = game:GetService("Players")

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
    
    Replication.requestGameSettings()
    local stats = Replication.getUserStats()
 
    Replication.getUserSettings()

    ActionHandler.init(world)
    UIBase.init(world, stats)

    if not stats.Keep or stats.Keep == "" then
        ViewWorld.displayWorld(world)
        ClientPreload.tellReady()
        wait(2)
        repeat
            wait()
        until ClientPreload.FullyLoaded
    
        UIBase.showInDevelopmentWarning(status)
        UIBase.waitForPromptDismissal()
        UIBase.displayPartitionOverview()

        --UIBase.displayInfoPrompt("Hi there", "Welcome to Pioneers. To begin you need to build a keep. Choose a spot ")
        UIBase.choicePrompt(
            "Welcome to Pioneers!",
            "\nDouble click anywhere to place your keep and begin your kingdom.\n\n"..
            "Make sure to give yourself room to grow!",
            {
                {
                    Text = "Let's go!", 
                    Color = Color3.fromRGB(30, 136, 229),
                }
            })
        UIBase.disableManagedInput()
        UIBase.waitForPartitionOverviewDismissal()
        Replication.spawnConfirm()
    else
        _G.updateLoadStatus("Map", "⭕Fetching map info...")
        Replication.requestSpawn(Util.positionStringToVector(stats.Keep))
        
        repeat wait() until Players.LocalPlayer.Character

        ViewWorld.displayWorld(world)

        repeat
            wait()
        until ClientPreload.FullyLoaded
    
        Replication.spawnConfirm()
    end

    --[[if not UserSettings.hasDoneTutorial() then
        UIBase.showTutorialPrompt()
    end]]--

    --UIBase.waitForPromptDismissal()
    UIBase.showStats()
    UIBase.showLocation()
    --UIBase.showChatBox()
    UIBase.showFeedbackButton()
    --UIBase.showFindKingdomButton()
    UIBase.showBuildButton()
    UIBase.showProgressionUI(stats)
    UIBase.showUnitControlButton()
    UIBase.enableManagedInput()
end

local UIS = game:GetService("UserInputService")
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

        for i, v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            v:Destroy()
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

spawn(function()
    while wait() do
        local char = game.Players.LocalPlayer.Character

        if char and char:FindFirstChild("HumanoidRootPart") then
            local p = char.HumanoidRootPart
            if p.Position.Y < -10 then
                p.CFrame = CFrame.new(p.Position) + Vector3.new(0, 50, 0)
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        local char = game.Players.LocalPlayer.Character

        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 150
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        local char = game.Players.LocalPlayer.Character

        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
        end
    end
end)

start()

