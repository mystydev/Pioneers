local ViewUnit = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common

local ClientUtil = require(Client.ClientUtil)
local Util       = require(Common.Util)
local Unit       = require(Common.Unit)

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local clamp      = math.clamp
local UnitModel  = game.ReplicatedStorage.Pioneers.Assets.Capsule
local tweenInfo  = TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local unitToInstMap = {}
local instToUnitMap = {}

local modelSizeOffset = Vector3.new(2, 5, 2)

local function unload(tile, model) --TODO: fully unload from memory
    instToUnitMap[model] = nil
    unitToInstMap[tile] = nil
    model:Destroy()
end

local function autoUnload() --TODO: fully unload from memory
    local getPos = ClientUtil.getPlayerPosition
    local dist
    
    repeat
        for tile, model in pairs(unitToInstMap) do
            local position = model.Position
            dist = (position - getPos()).magnitude
            local n = clamp((((model.Size.x / 2)*20) + (300/(dist))^2-1)/21, 0, 1)
            model.Size = Vector3.new(n,n,n) * modelSizeOffset

            if dist > 1500 then
                unload(tile, model)
            end
        end

        RunService.Stepped:Wait()
    until false
end

function ViewUnit.getUnitFromInst(inst)
    return instToUnitMap[inst]
end

function ViewUnit.getInstFromUnit(unit)
    return unitToInstMap[unit]
end

function ViewUnit.displayUnit(unit)
    local model = UnitModel:Clone()

    unitToInstMap[unit] = model
    instToUnitMap[model] = unit

    model.CFrame = CFrame.new(Util.axialCoordToWorldCoord(unit.Position) + Vector3.new(0, 3, 0))
    model.Parent = Workspace
end

local positionCache = {}

function ViewUnit.updateDisplay(unit)
    local model = unitToInstMap[unit]
    
    if positionCache[unit] ~= unit.Position then
        local target = Util.axialCoordToWorldCoord(unit.Position) + Vector3.new(0, 3, 0)
        local tween = TweenService:Create(model, tweenInfo, {CFrame = CFrame.new(target)})

        tween:Play()
        positionCache[unit] = unit.Position
    end

end

spawn(autoUnload)

return ViewUnit