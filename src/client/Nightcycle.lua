local Nightcycle = {}

local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")

local DAY_LENGTH = 5 * 60 / 24
local DAYTIME_PREFERENCE = 3
local AMBIENT_TIME_OFFSET = 5
local AMBIENT_MIN    = 50
local AMBIENT_MAX    = 106
local AMBIENT_RANGE  = AMBIENT_MAX - AMBIENT_MIN
local BRIGHTNESS_MAX = 1
local BRIGHTNESS_MIN = 0.5
local BRIGHTNESS_RANGE  = BRIGHTNESS_MAX - BRIGHTNESS_MIN

local function updateLighting()

    local t = ((tick() / DAY_LENGTH) % 24) / 24 
    --local t = 0.6
    local brightness = 1 - (2 * math.abs(t - 0.5))^DAYTIME_PREFERENCE
    local ambient = brightness * AMBIENT_RANGE + AMBIENT_MIN

    Lighting.ClockTime = 12 * (2*t - 1)^DAYTIME_PREFERENCE + 12
    Lighting.Ambient = Color3.fromRGB(ambient, ambient, ambient)
    Lighting.OutdoorAmbient = Color3.fromRGB(ambient, ambient, ambient)
    Lighting.Brightness = brightness * BRIGHTNESS_RANGE + BRIGHTNESS_MIN
    
end


RunService.Stepped:Connect(updateLighting)

return Nightcyle