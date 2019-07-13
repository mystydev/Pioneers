local UserSettings = {}
local HttpService  = game:GetService("HttpService")
local Network      = game.ReplicatedStorage.Network

UserSettings.Store = {}
UserSettings.Settings = {}

function UserSettings.parseJSON(player, data)
    local settings = HttpService:JSONDecode(data)
    UserSettings.Store[player] = settings
end

function UserSettings.getUserSettings(player)
    return UserSettings.Store[player]
end

function UserSettings.defineLocalSettings(settings)
    UserSettings.Settings = settings
end

function UserSettings.pushLocalUpdate()
    Network.SettingsUpdate:FireServer(UserSettings.Settings)
end

function UserSettings.shouldShowDevelopmentWarning()
    return UserSettings.Settings.ShowDevelopmentWarning
end

function UserSettings.dontShowDeveloptmentWarning()
    UserSettings.Settings.ShowDevelopmentWarning = false
    UserSettings.pushLocalUpdate()
end

return UserSettings