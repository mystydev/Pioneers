local ViewUnit = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local World = require(Common.World)
local Unit  = require(Common.Unit)
local Util  = require(Common.Util)
local PID   = require(Common.PID)
local FiniteStateMachine = require(Common.FiniteStateMachine)
local RunService = game:GetService("RunService")

--Instance is the unit model
local instanceToUnitMap = {}
local unitToInstanceMap = {}
local modelToUnitMap = {}
local currentWorld

local POSITION_OFFSET = Vector3.new(0, 5, 0)
local WALK_VELOCITY = 0.50
local MAX_FATIGUE = 10

local instanceDefaults = {velocity = 0, heading = 0}

local instanceModels = {}
instanceModels[Unit.NONE]       = {unit = Assets.Villager, tool = nil}
instanceModels[Unit.VILLAGER]   = {unit = Assets.Villager, tool = nil}
instanceModels[Unit.FARMER]     = {unit = Assets.Villager, tool = Assets.Hoe}
instanceModels[Unit.LUMBERJACK] = {unit = Assets.Villager, tool = Assets.Axe}
instanceModels[Unit.MINER]      = {unit = Assets.Villager, tool = Assets.Pickaxe}
instanceModels[Unit.APPRENTICE] = {unit = Assets.Villager, tool = Assets.Spear}
instanceModels[Unit.SOLDIER]    = {unit = Assets.Soldier, tool = Assets.Spear}

--Prevent tool from physics sleeping and no longer moving with animation
local function giveToolInsomnia(model)
    spawn(function()
        local victim = model.Handle.AlignPosition

        while model.Parent do
            victim.LimitsEnabled = true
            victim.LimitsEnabled = false

            wait(0.2)
        end
    end)
end

local function getNewInstanceFromUnitType(type)
    local newInstance = Util.tableCopy(instanceDefaults)

    newInstance.model = instanceModels[type].unit:Clone()
    newInstance.tool = instanceModels[type].tool and instanceModels[type].tool:Clone()
    newInstance.pidInfo = PID.newController()
    newInstance.fsm = FiniteStateMachine.newMachine(Unit.UnitState, Unit.UnitState.IDLE)

    FiniteStateMachine.addTransition(newInstance.fsm, Unit.UnitState.IDLE, Unit.UnitState.MOVING, ViewUnit.transitionIdleToMoving)
    FiniteStateMachine.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.MOVING, ViewUnit.transitionMovingToMoving)
    FiniteStateMachine.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.IDLE, ViewUnit.transitionMovingToIdle)
    FiniteStateMachine.addTransition(newInstance.fsm, Unit.UnitState.WORKING, Unit.UnitState.MOVING, ViewUnit.transitionWorkToMoving)
    FiniteStateMachine.addTransition(newInstance.fsm, Unit.UnitState.WORKING, Unit.UnitState.WORKING, ViewUnit.transitionWorkToWork)
    FiniteStateMachine.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.WORKING, ViewUnit.transitionMovingToWork)

    if newInstance.tool then
        newInstance.tool.Parent = newInstance.model
    end

    return newInstance
end

local function cframeToHeading(cf)
    local _, y, _ = cf:ToOrientation()
    return y
end

local function headingDifference(heading, targetHeading)
    assert(heading <= math.pi and heading >= -math.pi, "invalid heading: " .. heading)
    assert(targetHeading <= math.pi and targetHeading >= -math.pi, "invalid target heading: " .. targetHeading)

    local difference = targetHeading - heading
    local absDifference = math.abs(difference)

    if absDifference < math.pi then
        return absDifference == math.pi and absDifference or difference
    elseif targetHeading > heading then
        return absDifference - math.pi * 2
    else 
        return math.pi * 2 - absDifference
    end
end

local function equipTool(instance, unit)
    local model = instance.model
    local tool = instance.tool

    tool.Handle.AlignPosition.Attachment1 = model.RightHand.RightGripAttachment
    tool.Handle.AlignOrientation.Attachment1 = model.RightHand.RightGripAttachment
    tool.SecondHandle.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
end

local function unequipTool(instance, unit)
    local model = instance.model
    local tool = instance.tool

    tool.Handle.AlignPosition.Attachment1 = model.UpperTorso.ToolBackAttach
    tool.Handle.AlignOrientation.Attachment1 = model.UpperTorso.ToolBackAttach
    tool.SecondHandle.AlignPosition.Attachment1 = nil
end

--Create a new unit instance
local function initiateNewUnit(unit)
    assert(unit, "Undefined unit passed to initiateNewUnit")
    assert(not unitToInstanceMap[unit], "Initiating new unit view when unit view is already initiated!")

    local instance = getNewInstanceFromUnitType(unit.Type)
    local model = instance.model

    unitToInstanceMap[unit] = instance
    instanceToUnitMap[instance] = unit
    modelToUnitMap[model] = unit

    local worldPosition = Util.axialCoordToWorldCoord(unit.Position)
    model:SetPrimaryPartCFrame(CFrame.new(worldPosition + POSITION_OFFSET))
    model.Parent = workspace
    unequipTool(instance, unit)

    return instance
end

local function displayUpdateLoop(time, frameDelta)
    for unit, instance in pairs(unitToInstanceMap) do
        ViewUnit.stepDisplay(unit, instance, frameDelta)
    end
end

--Update already existing view to closer resemble underlying data
function ViewUnit.stepDisplay(unit, instance, frameDelta)
    local model = instance.model

    local worldPosition = Util.axialCoordToWorldCoord(unit.Position) + POSITION_OFFSET
    local viewPosition = model.PrimaryPart.Position
    local viewDelta = worldPosition - viewPosition
    local viewOrientation = model.PrimaryPart.CFrame - model.PrimaryPart.Position
    local viewHeading = cframeToHeading(viewOrientation)

    if viewDelta.Magnitude < 1 then
        return
    end

    local targetVelocity = viewDelta.Magnitude * WALK_VELOCITY
    instance.velocity = instance.velocity + (targetVelocity - instance.velocity) * frameDelta / (instance.velocity + 0.1)

    local targetHeading = cframeToHeading(CFrame.new(viewPosition, worldPosition))
    local headingDelta = headingDifference(viewHeading, targetHeading)
    local newPosition = viewPosition + viewOrientation * Vector3.new(0,0,-1) * instance.velocity * frameDelta
    local newHeading = viewHeading - PID.getValue(instance.pidInfo, headingDelta, frameDelta)
    local newOrientation = CFrame.Angles(0, newHeading, 0)

    model:SetPrimaryPartCFrame(newOrientation + newPosition)
    model.Parent = workspace

    if instance.currentAnim and instance.currentAnim.Animation == Assets.Animations.Walking then
        instance.currentAnim:AdjustSpeed(instance.velocity / 6.5)
    end
end

function ViewUnit.updateDisplay(unit, frameDelta)
    assert(unit, "Undefined unit passed to updateDisplay")
    assert(unitToInstanceMap[unit], "Updating display for uninitialised unit view")

    local instance = unitToInstanceMap[unit]
    local transition = FiniteStateMachine.toState(instance.fsm, unit.State)

    if transition then
        transition(instance, unit)
    end
end

function ViewUnit.init(world)
    currentWorld = world
    RunService.Stepped:Connect(displayUpdateLoop)
end

function ViewUnit.transitionIdleToMoving(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        --currentAnimation:Stop()
        --currentAnimation:Destroy()
    end

    if instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(Assets.Animations.Walking)
        newAnim:Play(2)
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionWorkToMoving(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop(0.5)
    end

    if instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(Assets.Animations.Walking)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionMovingToWork(instance, unit)
    local currentAnimation = instance.currentAnim

    if instance.model.Parent then
        local grabAnim = instance.model.Humanoid:LoadAnimation(Assets.Animations.GetTool)
        grabAnim:Play(2)

        delay(1, function()
            local workAnim = instance.model.Humanoid:LoadAnimation(Assets.Animations.Working)
            workAnim:Play(2)
            instance.currentAnim = workAnim
        
            equipTool(instance, unit)
            wait(0.5)
            grabAnim:Stop(0.5)
        end)
    end

    if currentAnimation then
        currentAnimation:Stop(2)
    end
end

function ViewUnit.transitionWorkToWork(instance, unit)
    if unit.Fatigue >= MAX_FATIGUE then
        if instance.currentAnim then instance.currentAnim:Stop(2) end
        local newAnim = instance.model.Humanoid:LoadAnimation(Assets.Animations.PutTool)
        newAnim:Play(1)
        instance.currentAnim = newAnim
        instance.tool.SecondHandle.AlignPosition.Attachment1 = nil
        delay(2, function() 
            unequipTool(instance, unit)
        end)
    elseif not instance.currentAnim and instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(Assets.Animations.Working)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionMovingToMoving(instance, unit)
    if not instance.currentAnim and instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(Assets.Animations.Walking)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionMovingToIdle(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop()
        currentAnimation:Destroy()
    end
end

function ViewUnit.getUnitFromInst(inst)
    if not inst then
        return end
    
    if inst.Name == "Handle" then
        inst = inst.Parent
    end

    if not inst:IsA("Model") and inst.Parent:IsA("Model") then
        inst = inst.Parent
    end
    
    return modelToUnitMap[inst]
end

function ViewUnit.getInstFromUnit(unit)
    return unitToInstanceMap[unit] and unitToInstanceMap[unit].model
end

function ViewUnit.displayUnit(unit, oldModel)
    initiateNewUnit(unit)
    ViewUnit.updateDisplay(unit)
end

function ViewUnit.removeUnit(unit)

end

function ViewUnit.convertIdListToUnits(list)
    return World.convertIdListToUnits(currentWorld.Units, list)
end

function ViewUnit.convertIdListToInsts(list)
    if not list then return end

    local unitList = World.convertIdListToUnits(currentWorld.Units, list)
    local insts = {}

    for _, unit in pairs(unitList) do
        table.insert(insts, unitToInstanceMap[unit].model)
    end

    return insts
end

function ViewUnit.provideUIBase(base)

end

return ViewUnit