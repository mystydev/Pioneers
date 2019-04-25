local function start()

    local Client = script
    local Common = game.ReplicatedStorage.Pioneers.Common

    local ClientPreload = require(Client.ClientPreload)
    ClientPreload.init()

    local ViewWorld       = require(Client.ViewWorld)
    local ViewStats       = require(Client.ViewStats)
    Replication     = require(Client.Replication)
    local ObjectSelection = require(Client.ObjectSelection)
    local World           = require(Common.World)

    print("Pioneers client waiting for server to be ready")

    repeat wait() until Replication.ready()

    print("Pioneers client starting...")

    world = World.new()

    Replication.init(world)
    ViewWorld.displayWorld(world)

    local stats = Replication.getUserStats()

    ClientPreload.tellReady()

    ObjectSelection.init(world, stats)
    ViewStats.init(stats)

end

local LogService = game:GetService("LogService")

LogService.MessageOut:Connect(function(message, type)
    if string.find(message, "Pion unrecoverable") then
        print("Pioneers client experienced an unrecoverable error... Automatically restarting!")

        Replication.worldDied()

        for i, v in pairs(workspace:GetChildren()) do
            if (v:IsA("BasePart") or v:IsA("Model")) and v.Name ~= "Terrain" then
                v:Destroy()
            end
        end

        if world then
            world.Tiles = {}
            world.Units = {}
            world.Dead = true
        end

        game.Lighting.ColorCorrection:Destroy()
        game.Lighting.Blur:Destroy()

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