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

    print("Pioneers client waiting for server to be ready")

    repeat wait() until Replication.ready()

    print("Pioneers client starting...")
    
    SoundManager.init()
    world = World.new()

    Replication.init(world)
    ViewWorld.displayWorld(world)

    local stats = Replication.getUserStats()

    ClientPreload.tellReady()

    ActionHandler.init(world)
    UIBase.init(world)
    UIBase.showStats(stats)
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
game.StarterGui:SetCore("ResetButtonCallback", resetBindable)

start()