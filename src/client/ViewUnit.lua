local ViewUnit = {}

local Common = game.ReplicatedStorage.Pioneers.Common
local Util = require(Common.Util)
local Unit = require(Common.Unit)

local UnitModel = game.ReplicatedStorage.Pioneers.Assets.Capsule
local DisplayCol = {}

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)


DisplayCol[Unit.NONE]     = Color3.fromRGB(0,0,0)
DisplayCol[Unit.VILLAGER] = Color3.fromRGB(160,95,53)
DisplayCol[Unit.SOLDIER]  = Color3.fromRGB(220,20,60)

unitToInstMap = {}
instToUnitMap = {}

function ViewUnit.getUnitFromInst(inst)
    return instToUnitMap[inst]
end

function ViewUnit.displayUnit(unit)
    local model = UnitModel:Clone()

    unitToInstMap[unit] = model
    instToUnitMap[model] = unit

    model.CFrame = CFrame.new(Util.axialCoordToWorldCoord(unit.Position) + Vector3.new(0, 3, 0))
    model.Parent = Workspace
    model.Color = DisplayCol[unit.Type]
end


function ViewUnit.updateDisplay(unit)
    local model = unitToInstMap[unit]
    
    local tween = TweenService:Create(model, tweenInfo, {CFrame = CFrame.new(Util.axialCoordToWorldCoord(unit.Position) + Vector3.new(0, 3, 0))})
    tween:Play()
    model.Color = DisplayCol[unit.Type]
end

return ViewUnit