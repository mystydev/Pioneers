local ViewUnit = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local World = require(Common.World)
local Unit  = require(Common.Unit)
local Util  = require(Common.Util)
local PID   = require(Common.PID)
local FSM   = require(Common.FiniteStateMachine)
local RunService = game:GetService("RunService")

--Instance is the unit model
local instanceToUnitMap = {}
local unitToInstanceMap = {}
local modelToUnitMap = {}
local currentWorld

local POSITION_OFFSET = Vector3.new(0, 5, 0)
local WALK_VELOCITY = 0.8
local MAX_FATIGUE = 10

local instanceDefaults = {velocity = 0, heading = 0, lookatHeading = 0}

local instanceModels = {}
instanceModels[Unit.NONE]       = {unit = Assets.Villager, tool = nil}
instanceModels[Unit.VILLAGER]   = {unit = Assets.Villager, tool = nil}
instanceModels[Unit.FARMER]     = {unit = Assets.Villager, tool = Assets.Hoe}
instanceModels[Unit.LUMBERJACK] = {unit = Assets.Villager, tool = Assets.Axe}
instanceModels[Unit.MINER]      = {unit = Assets.Villager, tool = Assets.Pickaxe}
instanceModels[Unit.APPRENTICE] = {unit = Assets.Villager, tool = Assets.Spear}
instanceModels[Unit.SOLDIER]    = {unit = Assets.Soldier, tool = Assets.Spear}

local typeSpecificAnims = {}
typeSpecificAnims[Unit.VILLAGER] = {
    Walking = Assets.Animations.Villager.Walking,
    Working = Assets.Animations.Villager.Working,
    GetTool = Assets.Animations.Villager.GetTool,
    PutTool = Assets.Animations.Villager.PutTool}

typeSpecificAnims[Unit.NONE] = typeSpecificAnims[Unit.VILLAGER]
typeSpecificAnims[Unit.FARMER] = typeSpecificAnims[Unit.VILLAGER]
typeSpecificAnims[Unit.LUMBERJACK] = typeSpecificAnims[Unit.VILLAGER]
typeSpecificAnims[Unit.MINER] = typeSpecificAnims[Unit.VILLAGER]

typeSpecificAnims[Unit.SOLDIER] = {
    Walking = Assets.Animations.Soldier.Walking,
    Combat = Assets.Animations.Soldier.SpearCombat,
    GetTool = Assets.Animations.Soldier.GetTool,
    PutTool = Assets.Animations.Soldier.PutTool,
    Guard = Assets.Animations.Soldier.SpearGuard,
    Dies = Assets.Animations.Soldier.Dies}

typeSpecificAnims[Unit.APPRENTICE] = typeSpecificAnims[Unit.SOLDIER]

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
    newInstance.fsm = FSM.newMachine(Unit.UnitState, Unit.UnitState.IDLE)

    FSM.addTransition(newInstance.fsm, Unit.UnitState.IDLE, Unit.UnitState.MOVING, ViewUnit.transitionIdleToMoving)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.IDLE, Unit.UnitState.WORKING, ViewUnit.transitionMovingToWork)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.MOVING, ViewUnit.transitionMovingToMoving)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.IDLE, ViewUnit.transitionMovingToIdle)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.WORKING, Unit.UnitState.MOVING, ViewUnit.transitionWorkToMoving)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.WORKING, Unit.UnitState.WORKING, ViewUnit.transitionWorkToWork)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.WORKING, ViewUnit.transitionMovingToWork)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.TRAINING, Unit.UnitState.TRAINING, ViewUnit.transitionTrainingToTraining)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.TRAINING, Unit.UnitState.MOVING, ViewUnit.transitionTrainingToMoving)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.TRAINING, ViewUnit.transitionMovingToTraining)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.GUARDING, Unit.UnitState.GUARDING, ViewUnit.transitionGuardingToGuarding)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.GUARDING, Unit.UnitState.MOVING, ViewUnit.transitionGuardingToMoving)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.GUARDING, ViewUnit.transitionMovingToGuarding)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.COMBAT, Unit.UnitState.COMBAT, ViewUnit.transitionCombatToCombat)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.COMBAT, Unit.UnitState.MOVING, ViewUnit.transitionCombatToMoving)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.COMBAT, ViewUnit.transitionMovingToCombat)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.GUARDING, Unit.UnitState.COMBAT, ViewUnit.transitionGuardingToCombat)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.COMBAT, Unit.UnitState.GUARDING, ViewUnit.transitionCombatToGuarding)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.COMBAT, Unit.UnitState.DEAD, ViewUnit.transitionAnyToDead)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.IDLE, Unit.UnitState.DEAD, ViewUnit.transitionAnyToDead)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.MOVING, Unit.UnitState.DEAD, ViewUnit.transitionAnyToDead)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.GUARDING, Unit.UnitState.DEAD, ViewUnit.transitionAnyToDead)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.TRAINING, Unit.UnitState.DEAD, ViewUnit.transitionAnyToDead)

    if newInstance.tool then
        newInstance.tool.Parent = newInstance.model
        giveToolInsomnia(newInstance.tool)
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

local function attackHeading(instance, unit)
    local attackTile = unit.Attack
    local attackUnit = unit.AttackUnit

    if not attackTile and not attackUnit then
        return end

    local attackPosition

    if attackTile then
        local tile = World.getTile(currentWorld.Tiles, attackTile)
        attackPosition = Util.axialCoordToWorldCoord(tile.Position)
    else
        local unitId = string.split(attackUnit, ':')[2]
        local unit = World.getUnit(currentWorld.Units, unitId)
        local model = ViewUnit.getInstFromUnit(unit)

        if model then
            attackPosition = model.HumanoidRootPart.Position
        end
    end

    if not attackPosition then return 0 end

    local viewPosition = instance.model.PrimaryPart.Position
    local adjustedTarget = Vector3.new(attackPosition.x, viewPosition.y, attackPosition.z)
    local direction = CFrame.new(viewPosition, adjustedTarget)

    return cframeToHeading(direction)
end

local function equipTool(instance, unit)
    local model = instance.model
    local tool = instance.tool
    
    if not tool then return end

    tool.Handle.AlignPosition.Attachment1 = model.RightHand.RightGripAttachment
    tool.Handle.AlignOrientation.Attachment1 = model.RightHand.RightGripAttachment
    tool.SecondHandle.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
end

local function unequipTool(instance, unit)
    local model = instance.model
    local tool = instance.tool

    if not tool then return end

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

    if viewDelta.Magnitude > 0.5 then
        instance.lookatHeading = cframeToHeading(CFrame.new(viewPosition, worldPosition))
        local targetVelocity = viewDelta.Magnitude * WALK_VELOCITY
        instance.velocity = instance.velocity + (targetVelocity - instance.velocity) * frameDelta / (instance.velocity + 0.1)
    else
        instance.velocity = 0
    end

    if viewDelta.Magnitude < 0.5 and (unit.Attack or unit.AttackUnit) then  
        instance.lookatHeading = attackHeading(instance, unit)
        --instance.velocity = instance.velocity / 1.1
    end

    unit.lookatHeading = instance.lookatHeading or "none"

    --is lookatHeading nan
    if instance.lookatHeading ~= instance.lookatHeading then 
        return end 

    local headingDelta = headingDifference(viewHeading, instance.lookatHeading)
    local newPosition = viewPosition + viewOrientation * Vector3.new(0,0,-1) * instance.velocity * frameDelta
    local newHeading = viewHeading - PID.getValue(instance.pidInfo, headingDelta, frameDelta) * (1 + instance.velocity / 10)
    local newOrientation = CFrame.Angles(0, newHeading, 0)

    model:SetPrimaryPartCFrame(newOrientation + newPosition)
    model.Parent = workspace

    if instance.currentAnim and instance.currentAnim.Animation == typeSpecificAnims[unit.Type].Walking then
        instance.currentAnim:AdjustSpeed(instance.velocity / 6.5)
    end
end

function ViewUnit.updateDisplay(unit, frameDelta)
    assert(unit, "Undefined unit passed to updateDisplay")
    assert(unitToInstanceMap[unit], "Updating display for uninitialised unit view")

    local instance = unitToInstanceMap[unit]
    local transition = FSM.toState(instance.fsm, unit.State)

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
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Walking)
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
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Walking)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionMovingToWork(instance, unit)
    local currentAnimation = instance.currentAnim

    if instance.model.Parent then
        local grabAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].GetTool)
        grabAnim:Play(2)

        delay(1, function()
            local workAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Working)
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
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].PutTool)
        newAnim:Play(1)
        instance.currentAnim = newAnim
        instance.tool.SecondHandle.AlignPosition.Attachment1 = nil
        delay(2, function() 
            unequipTool(instance, unit)
        end)
    elseif not instance.currentAnim and instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Working)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionMovingToMoving(instance, unit)
    if not instance.currentAnim and instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Walking)
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

function ViewUnit.transitionIdleToTraining(instance, unit)

end

function ViewUnit.transitionTrainingToTraining(instance, unit)
    if not instance.currentAnim and instance.model.Parent then
        equipTool(instance, unit)
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Combat)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionTrainingToMoving(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop(0.5)
    end

    local putAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].PutTool)
    putAnim:Play(1)

    local walkAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Walking)
    walkAnim:Play(2)

    instance.currentAnim = walkAnim
    instance.tool.SecondHandle.AlignPosition.Attachment1 = nil
    delay(2, function() 
        unequipTool(instance, unit)
        putAnim:Stop(0.5)
    end)
end

function ViewUnit.transitionMovingToTraining(instance, unit)
    local currentAnimation = instance.currentAnim

    if instance.model.Parent then
        local grabAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].GetTool)
        grabAnim:Play(2)

        delay(1, function()
            local workAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Combat)
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

function ViewUnit.transitionMovingToGuarding(instance, unit)
    local currentAnimation = instance.currentAnim

    if instance.model.Parent then
        local grabAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].GetTool)
        grabAnim:Play(2)

        delay(1, function()
            local workAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Guard)
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

function ViewUnit.transitionGuardingToMoving(instance, unit)
    ViewUnit.transitionTrainingToMoving(instance, unit)
end

function ViewUnit.transitionGuardingToGuarding(instance, unit)
    if not instance.currentAnim and instance.model.Parent then
        equipTool(instance, unit)
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Guard)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionCombatToCombat(instance, unit)
    if not instance.currentAnim and instance.model.Parent then
        equipTool(instance, unit)
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Combat)
        newAnim:Play()
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionCombatToMoving(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop(0.5)
    end

    local putAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].PutTool)
    putAnim:Play(1)

    local walkAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Walking)
    walkAnim:Play(2)

    instance.currentAnim = walkAnim
    instance.tool.SecondHandle.AlignPosition.Attachment1 = nil
    delay(2, function() 
        unequipTool(instance, unit)
        putAnim:Stop(0.5)
    end)
end

function ViewUnit.transitionMovingToCombat(instance, unit)
    local currentAnimation = instance.currentAnim

    if instance.model.Parent then
        local grabAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].GetTool)
        grabAnim:Play(2)

        delay(1, function()
            local workAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Combat)
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

function ViewUnit.transitionGuardingToCombat(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop()
    end

    local anim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Combat)
    anim:Play(2)
    instance.currentAnim = anim

    equipTool(instance, unit)
end

function ViewUnit.transitionCombatToGuarding(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop()
    end

    local anim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Guard)
    anim:Play(2)
    instance.currentAnim = anim

    equipTool(instance, unit)
end

function ViewUnit.transitionAnyToDead(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop(0.5)
    end

    local anim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Dies)
    anim:Play()
    anim:AdjustSpeed(1.5)
    instance.currentAnim = anim

    delay(2.4, function()
        anim:AdjustSpeed(0)
    end)
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