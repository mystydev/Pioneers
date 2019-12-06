local ViewUnit = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local World = require(Common.World)
local Unit  = require(Common.Unit)
local Util  = require(Common.Util)
local PID   = require(Common.PID)
local FSM   = require(Common.FiniteStateMachine)
local ClientUtil = require(Client.ClientUtil)
local RunService = game:GetService("RunService")

--Instance is the unit model
local instanceToUnitMap = {}
local unitToInstanceMap = {}
local modelToUnitMap = {}
local currentWorld

local POSITION_OFFSET = Vector3.new(0, 5, 0)
local WALK_VELOCITY = 0.5 --1/seconds to walk required distance
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
    StartWalk = Assets.Animations.Villager.StartWalk,
    Walking   = Assets.Animations.Villager.Walking,
    StopWalk  = Assets.Animations.Villager.StopWalk,
    Working   = Assets.Animations.Villager.Working,
    GetTool   = Assets.Animations.Villager.GetTool,
    PutTool   = Assets.Animations.Villager.PutTool,
    Dies = Assets.Animations.Soldier.Dies}

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

local StatusIds = {}
StatusIds.FOOD = "rbxassetid://3101321804"
StatusIds.WOOD = "rbxassetid://3101322014"
StatusIds.STONE = "rbxassetid://3101321954"
StatusIds.IDLE = "rbxassetid://3101321886"

local StatusCols = {}
StatusCols.FOOD = ColorSequence.new(Color3.fromRGB(235, 203, 108))
StatusCols.WOOD = ColorSequence.new(Color3.fromRGB(46, 125, 50))
StatusCols.STONE = ColorSequence.new(Color3.fromRGB(120, 120, 120))
StatusCols.IDLE = ColorSequence.new(Color3.fromRGB(171, 8, 0))

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

local function equipTool(instance, unit)
    local model = instance.model
    local tool = instance.tool
    
    if not tool then return end

    tool.Handle.AlignPosition.Attachment1 = model.RightHand.RightGripAttachment
    tool.Handle.AlignOrientation.Attachment1 = model.RightHand.RightGripAttachment
    tool.SecondHandle.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
end

local function equipToolWithRightHand(instance, unit)
    local model = instance.model
    local tool = instance.tool
    
    if not tool then return end

    tool.Handle.AlignPosition.Attachment1 = model.RightHand.RightGripAttachment
    tool.Handle.AlignOrientation.Attachment1 = model.RightHand.RightGripAttachment
end

local function unequipTool(instance, unit)
    local model = instance.model
    local tool = instance.tool

    if not tool then return end

    tool.Handle.AlignPosition.Attachment1 = model.UpperTorso.ToolBackAttach
    tool.Handle.AlignOrientation.Attachment1 = model.UpperTorso.ToolBackAttach
    tool.SecondHandle.AlignPosition.Attachment1 = nil
end

local function unequipToolWithLeftHand(instance, unit)
    local model = instance.model
    local tool = instance.tool

    if not tool then return end

    tool.SecondHandle.AlignPosition.Attachment1 = nil
end

local function displayIdlePopup(instance, unit)
    local model = instance.model

    model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.IDLE
    model.HumanoidRootPart.StatusEmitter.Color = StatusCols.IDLE
    model.HumanoidRootPart.StatusEmitter.Rate = 1/10
    model.HumanoidRootPart.StatusEmitter.Size = NumberSequence.new(4)
    model.HumanoidRootPart.StatusEmitter.Enabled = true
    model.HumanoidRootPart.StatusEmitter.Lifetime = NumberRange.new(3)
end

local function displayWorkPopup(instance, unit)
    local model = instance.model

    if unit.Type == Unit.MINER then
        
        model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.STONE
        model.HumanoidRootPart.StatusEmitter.Color = StatusCols.STONE
    elseif unit.Type == Unit.LUMBERJACK then
        model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.WOOD
        model.HumanoidRootPart.StatusEmitter.Color = StatusCols.WOOD
    elseif unit.Type == Unit.FARMER then
        model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.FOOD
        model.HumanoidRootPart.StatusEmitter.Color = StatusCols.FOOD
    end

    unit.PerRoundProduce = unit.PerRoundProduce or 0
    local rate = math.clamp(unit.PerRoundProduce/4, 0, 2.5)

    model.HumanoidRootPart.StatusEmitter.Enabled = true
    model.HumanoidRootPart.StatusEmitter.Rate = rate
    model.HumanoidRootPart.StatusEmitter.Size = NumberSequence.new(rate^1.5)
end

local function disablePopup(instance, unit)
    local model = instance.model

    model.HumanoidRootPart.StatusEmitter.Lifetime = NumberRange.new(1)
    model.HumanoidRootPart.StatusEmitter.Enabled = false
end

local function checkToolAssignment(instance, unit)
    if (not instance.tool) and instanceModels[unit.Type].tool then
        instance.tool = instanceModels[unit.Type].tool:Clone()
        instance.tool.Parent = instance.model
        instance.tool.CFrame = instance.model.HumanoidRootPart.CFrame
        unequipTool(instance, unit)
        giveToolInsomnia(instance.tool)
    end

    if instance.tool and (not instanceModels[unit.Type].tool or instance.tool.Name ~= instanceModels[unit.Type].tool.Name) then
        instance.tool:Destroy()
        instance.tool = nil
        checkToolAssignment(instance, unit)
    end
end

local function getNewInstanceFromUnitType(type)
    local newInstance = Util.tableCopy(instanceDefaults)

    newInstance.model = instanceModels[type].unit:Clone()
    newInstance.tool = instanceModels[type].tool and instanceModels[type].tool:Clone()
    newInstance.headingPidInfo = PID.newController({PreviousError = 0, I = 0, SetPoint = 0, Kp = 0.3 / 60, Ki = 4 / 60, Kd = 0, integral_limiter = 1.05})
    newInstance.velocityPidInfo = PID.newController({PreviousError = 0, I = 0, SetPoint = 0, Kp = 0.3 / 60, Ki = 2 / 60, Kd = 0, integral_limiter = 1.05})
    newInstance.fsm = FSM.newMachine(Unit.UnitState, Unit.UnitState.IDLE)

    FSM.addTransition(newInstance.fsm, Unit.UnitState.IDLE, Unit.UnitState.IDLE, ViewUnit.transitionIdleToIdle)
    FSM.addTransition(newInstance.fsm, Unit.UnitState.RESTING, Unit.UnitState.MOVING, ViewUnit.transitionRestingToMoving)
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
    FSM.addTransition(newInstance.fsm, Unit.UnitState.WORKING, Unit.UnitState.DEAD, ViewUnit.transitionAnyToDead)

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
    assert(math.pi - math.abs(targetHeading) >= -0.01, "invalid target heading: " .. targetHeading)

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

local function getUnitAttackPosition(unitKey)
    local unitId = string.split(unitKey, ':')[2]
    local unit = World.getUnit(currentWorld.Units, unitId)
    local model = ViewUnit.getInstFromUnit(unit)

    if model then
        return model.HumanoidRootPart.Position
    end
end

local function attackHeading(instance, unit)
    local attackTile = unit.Attack
    local attackUnit = unit.AttackUnit

    if not attackTile and not attackUnit then
        warn("Returning 0 from attack heading due to no attack target")
        return 0 
    end

    local attackPosition

    if attackTile then
        local tile = World.getTile(currentWorld.Tiles, attackTile)
        attackPosition = Util.axialCoordToWorldCoord(tile.Position)
    else
        attackPosition = getUnitAttackPosition(attackUnit)
    end

    if not attackPosition then 
        warn("Returning 0 from attack heading due to no attack position")
        return 0 
    end

    local viewPosition = instance.model.PrimaryPart.Position
    local adjustedTarget = Vector3.new(attackPosition.x, viewPosition.y, attackPosition.z)
    local direction = CFrame.new(viewPosition, adjustedTarget)

    return cframeToHeading(direction)
end

local function queueAnimation(instance, unit, animation)

    if instance.currentAnim then
        instance.currentAnim:GetMarkerReachedSignal("Finished"):Wait()
    end

    local nextAnim = instance.model.Humanoid:LoadAnimation(animation)
    nextAnim:Play()
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

local function deleteUnitInstance(unit, instance)
    unitToInstanceMap[unit] = nil
    instanceToUnitMap[instance] = nil
    modelToUnitMap[instance.model] = nil
    instance.model:Destroy()
end

local updateTime = tick()
local function displayUpdateLoop(time, frameDelta)
    local viewPosition = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())

    updateTime = tick()
    for unit, instance in pairs(unitToInstanceMap) do
        ViewUnit.stepDisplay(unit, instance, frameDelta, viewPosition)
    end
end

--Update already existing view to closer resemble underlying data
function ViewUnit.stepDisplay(unit, instance, frameDelta, viewPosition)
    if unit.Health <= 0 or unit.State == Unit.UnitState.DEAD then
        return end

    if unit.preventUpdates then
        return end
    
    local model = instance.model
    local viewDistance = (unit.Position - viewPosition).magnitude

    if viewDistance > ClientUtil.getCurrentViewDistance() then
        --model.Parent = nil
        instance.unloaded = true
        return
    elseif instance.unloaded then
        --model.Parent = workspace
        instance.unloaded = nil
    end

    if (updateTime - (unit.lastStep or 0)) < viewDistance / 300 then
        unit.missedDelta = (unit.missedDelta or 0) + frameDelta
        return end
    
    frameDelta = (unit.missedDelta or 0) + frameDelta
    unit.lastStep = updateTime
    unit.missedDelta = 0

    checkToolAssignment(instance, unit)

    --Calculate view distance and heading errors
    local worldPosition = Util.axialCoordToWorldCoord(unit.Position) + POSITION_OFFSET
    local viewPosition = model.PrimaryPart.Position
    local viewDelta = worldPosition - viewPosition
    local viewOrientation = model.PrimaryPart.CFrame - model.PrimaryPart.Position
    local viewHeading = cframeToHeading(viewOrientation)

    local positionOverrided = false

    --If the unit has an attack target, offset it's target position to be closer
    if Util.vectorToPositionString(unit.Position) == unit.Target and (unit.AttackUnit and viewDelta.magnitude < 20) then
        local attackPosition = getUnitAttackPosition(unit.AttackUnit)
        if attackPosition then
            worldPosition = attackPosition + (worldPosition - attackPosition).unit * 6
            viewDelta = worldPosition - viewPosition
            positionOverrided = true
        end
    end

    --If unit isn't close to it's target position update it's speed as usual
    --If the unit is at it's target position set velocity to 0 to prevent any overshoot
    if viewDelta.Magnitude > 0.5 then
        local targetVelocity = viewDelta.Magnitude * WALK_VELOCITY
        instance.lookatHeading = cframeToHeading(CFrame.new(viewPosition, worldPosition))
        instance.velocity = instance.velocity + PID.getValue(instance.velocityPidInfo, instance.velocity - targetVelocity, frameDelta)
    elseif not positionOverrided then
        instance.velocity = 0
    end

    --If unit is close to target and it has an attack target make it look at that attack target
    if viewDelta.Magnitude < 3 and positionOverrided then  
        instance.lookatHeading = attackHeading(instance, unit)
    end

    if viewDelta.Magnitude < 2 and positionOverrided then  
        instance.velocity = 0
    end

    --is lookatHeading nan
    if instance.lookatHeading ~= instance.lookatHeading then 
        return end 

    local headingDelta = headingDifference(viewHeading, instance.lookatHeading)
    local newPosition = viewPosition + viewOrientation * Vector3.new(0,0,-1) * instance.velocity * frameDelta
    local newHeading = viewHeading - PID.getValue(instance.headingPidInfo, headingDelta, frameDelta) * (1 + instance.velocity / 10)
    local newOrientation = CFrame.Angles(0, newHeading, 0)

    model.PrimaryPart.CFrame = newOrientation + newPosition
    --model:SetPrimaryPartCFrame(newOrientation + newPosition)
    --model.Parent = workspace

    if instance.currentAnim and instance.currentAnim.Animation == typeSpecificAnims[unit.Type].Walking then
        instance.currentAnim:AdjustSpeed(instance.velocity / 6.5)
    end
end

function ViewUnit.updateDisplay(unit, frameDelta)
    assert(unit, "Undefined unit passed to updateDisplay")

    if not unitToInstanceMap[unit] then
        warn("Updating display for uninitialised unit view")
        initiateNewUnit(unit)
    end

    if unit.preventUpdates then
        return end
    
    local instance = unitToInstanceMap[unit]
    local transition = FSM.toState(instance.fsm, unit.State)

    if transition and not instance.unloaded then
        transition(instance, unit)
    elseif instance.unloaded then
        local newPosition = Util.axialCoordToWorldCoord(unit.Position) + POSITION_OFFSET
        instance.model.PrimaryPart.CFrame = CFrame.new(newPosition)

        if instance.tool then
            instance.tool.CFrame = CFrame.new(newPosition)
        end

        if instance.currentAnim then
            instance.currentAnim:Stop(0)
            instance.currentAnim:Destroy()
            instance.currentAnim = nil
        end
    end
end

function ViewUnit.init(world)
    currentWorld = world
    RunService.Stepped:Connect(displayUpdateLoop)
end

function ViewUnit.transitionUnitType(unit, type)
    local instance = unitToInstanceMap[unit]
    local model = instance.model
    local newModel = instanceModels[type].unit
    local emitter = Assets.TypeChangeEffectEmitter:Clone()

    if model.Name == newModel.Name then
        return end

    model.Name = newModel.Name
    emitter.Parent = model.HumanoidRootPart
    wait(2)

    model.Humanoid:RemoveAccessories()

    for _, part in pairs(newModel:GetChildren()) do
        local newPart = part:Clone()
        local partType = newModel.Humanoid:GetBodyPartR15(part)

        if partType.Value < 15 then
            model.Humanoid:ReplaceBodyPartR15(partType, newPart)
        end
    end

    for _, accessory in pairs(newModel.Humanoid:GetAccessories()) do
        local newAccessory = accessory:Clone()
        newAccessory.Parent = model
        newAccessory.Handle.AccessoryWeld.Part1 = model.Head
    end

    unit.Type = type

    checkToolAssignment(instance, unit)

    if unit.State == Unit.UnitState.WORKING or unit.State == Unit.UnitState.TRAINING
    or unit.State == Unit.UnitState.GUARDING or unit.State == Unit.UnitState.COMBAT then
        equipTool(instance, unit)
    end

    emitter.Enabled = false
    ViewUnit.updateDisplay(unit)

    wait(3)

    emitter:Destroy()
end

function ViewUnit.transitionIdleToIdle(instance, unit)
    displayIdlePopup(instance, unit)
end

function ViewUnit.transitionIdleToMoving(instance, unit)
    disablePopup(instance, unit)
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

function ViewUnit.transitionRestingToMoving(instance, unit)
    local anims = instance.model.Humanoid:GetPlayingAnimationTracks()

    for i, v in pairs(anims) do
        v:Stop()
        v:Destroy()
    end

    if instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Walking)
        newAnim:Play(2)
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionWorkToMoving(instance, unit)
    disablePopup(instance, unit)
    local currentAnimation = instance.currentAnim

    if currentAnimation then
        currentAnimation:Stop(1)
    end

    if instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Walking)
        newAnim:Play(1)
        instance.currentAnim = newAnim
    end
end

function ViewUnit.transitionMovingToWork(instance, unit)
    local currentAnimation = instance.currentAnim

    if instance.model.Parent then
        local grabAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].GetTool)
        
        delay(1.3, function()

            if currentAnimation then
                currentAnimation:Stop(0.5)
            end

            grabAnim:Play(0.5)
            grabAnim:AdjustSpeed(1.5)

            wait(0.8)
            equipToolWithRightHand(instance, unit)
            wait(0.3)

            if instance.unloaded then return end

            local workAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Working)
            equipTool(instance, unit)
            workAnim:Play(1)
            workAnim:AdjustSpeed(1.3)
            instance.currentAnim = workAnim
        end)
    end

    displayWorkPopup(instance, unit)
end

function ViewUnit.transitionWorkToWork(instance, unit)
    if unit.Fatigue >= MAX_FATIGUE then

        if instance.currentAnim then instance.currentAnim:Stop(0.5) end

        delay(0, function()
            local putAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].PutTool)
            unequipToolWithLeftHand(instance, unit)
            putAnim:Play(1)
            putAnim:AdjustSpeed(1.2)
            instance.currentAnim = putAnim

            wait(1.5)
            unequipTool(instance, unit)
        end)
    elseif not instance.currentAnim and instance.model.Parent then
        local newAnim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Working)
        newAnim:Play()
        instance.currentAnim = newAnim
    end

    displayWorkPopup(instance, unit)
end

function ViewUnit.transitionMovingToMoving(instance, unit)
    disablePopup(instance, unit)
    unequipTool(instance, unit)
    if (not instance.currentAnim and instance.model.Parent)
        or (instance.currentAnim and instance.currentAnim.Animation ~= typeSpecificAnims[unit.Type].Walking) then
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
    walkAnim:Play(0.5)

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
    --local currentAnimation = instance.currentAnim

    --if currentAnimation then
    --    currentAnimation:Stop(0.5)
    --end
    disablePopup(instance, unit)
    local anims = instance.model.Humanoid:GetPlayingAnimationTracks()

    for i, v in pairs(anims) do
        v:Stop()
        v:Destroy()
    end

    local anim = instance.model.Humanoid:LoadAnimation(typeSpecificAnims[unit.Type].Dies)
    anim:Play()
    anim:AdjustSpeed(1.5)
    instance.currentAnim = anim

    delay(2.4, function()
        anim:AdjustSpeed(0)
    end)

    delay(15, function()
        local fading = 0
        while fading < 1 do
            local delta = RunService.Heartbeat:Wait()
            fading = fading + delta

            for _, part in pairs(instance.model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = part.Transparency + delta
                end
            end
        end

        deleteUnitInstance(unit, instance)
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

function ViewUnit.simDeath(unit)
    unit.Health = 0
    unit.State = Unit.UnitState.DEAD
    ViewUnit.updateDisplay(unit, 0)
    unit.preventUpdates = true
    delay(5, function()
        unit.preventUpdates = false
    end)
end

function ViewUnit.poofDisappear(unit)
    unit.State = Unit.UnitState.DEAD
    ViewUnit.updateDisplay(unit, 0)
    unit.preventUpdates = true

    local instance = unitToInstanceMap[unit]
    local smoke = Assets.SmokePuffEmitter:Clone()
    smoke.Parent = instance.model.HumanoidRootPart
    smoke:Emit(500)
    unit.preventUpdates = true

    delay(0.1, function()
        for _, part in pairs(instance.model:GetDescendants()) do 
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
    end)

    delay(15, function()
        deleteUnitInstance(unit, instance)
        unit.preventUpdates = false
    end)
end

return ViewUnit