local ViewUnit = {}

local Common = game.ReplicatedStorage.Pioneers.Common
local Util = require(Common.Util)
local Unit = require(Common.Unit)

local UnitModel = game.ReplicatedStorage.Pioneers.Assets.Capsule
local DisplayCol = {}

DisplayCol[Unit.NONE]     = Color3.fromRGB(0,0,0)
DisplayCol[Unit.VILLAGER] = Color3.fromRGB(240,230,140)
DisplayCol[Unit.SOLDIER]  = Color3.fromRGB(220,20,60)

function ViewUnit.displayUnit(unit)
    local model = UnitModel:Clone()

    model.CFrame = CFrame.new(Util.axialCoordToWorldCoord(unit.Position) + Vector3.new(0, 3, 0))
    model.Parent = Workspace
    model.Color = DisplayCol[unit.Type]
end

return ViewUnit