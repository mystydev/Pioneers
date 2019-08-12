local ViewUnit = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local ClientUtil   = require(Client.ClientUtil)
local SoundManager = require(Client.SoundManager)
local Util         = require(Common.Util)
local Unit         = require(Common.Unit)
local Tile         = require(Common.Tile)

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UIBase
local clamp      = math.clamp
local VillagerModel  = Assets.Villager
local SoldierModel = Assets.Soldier
local tweenInfo  = TweenInfo.new(2.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local fastTween  = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local POSITION_OFFSET = Vector3.new(0, 4.2, 0)

local walkAnimation = Instance.new("Animation")
walkAnimation.AnimationId = "rbxassetid://03090565308"
local mineAnimation = Instance.new("Animation")
mineAnimation.AnimationId = "rbxassetid://3090615222"
local putBackAnim = Instance.new("Animation")
putBackAnim.AnimationId = "rbxassetid://03090678702"
local getBackAnim = Instance.new("Animation")
getBackAnim.AnimationId = "rbxassetid://03090713020"
local spearAnim = Instance.new("Animation")
spearAnim.AnimationId = "rbxassetid://3112144281"
local spearGuardAnim = Instance.new("Animation")
spearGuardAnim.AnimationId = "rbxassetid://03115431882"

local StatusIds = {}
StatusIds.FOOD = "rbxassetid://3101321804"
StatusIds.WOOD = "rbxassetid://3101322014"
StatusIds.STONE = "rbxassetid://3101321954"
StatusIds.IDLE = "rbxassetid://3101321886"

local StatusCols = {}
StatusCols.FOOD = ColorSequence.new(Color3.fromRGB(255, 236, 179))
StatusCols.WOOD = ColorSequence.new(Color3.fromRGB(46, 125, 50))
StatusCols.STONE = ColorSequence.new(Color3.fromRGB(230, 230, 230))
StatusCols.IDLE = ColorSequence.new(Color3.fromRGB(171, 8, 0))

local unitToInstMap = {}
local instToUnitMap = {}

local modelSizeOffset = Vector3.new(2, 5, 2)

local currentWorld
function ViewUnit.init(w)
    currentWorld = w
end

local function unload(model) --TODO: fully unload from memory
    unitToInstMap[instToUnitMap[model]] = nil
    instToUnitMap[model] = nil
    model:Destroy()
end

local function autoUnload() --TODO: fully unload from memory
    local getPos = ClientUtil.getPlayerPosition
    local dist
    
    --[[repeat
        for tile, model in pairs(unitToInstMap) do
            local position = model.HumanoidRootPart.Position
            dist = (position - getPos()).magnitude
            --local n = clamp((((model.Size.x / 2)*20) + (300/(dist))^2-1)/21, 0, 1)
            --model.Size = Vector3.new(n,n,n) * modelSizeOffset

            if dist > 1500 then
                --unload(tile, model)
            end
        end

        RunService.Stepped:Wait()
    until false]]--
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
    
    return instToUnitMap[inst]
end

function ViewUnit.getInstFromUnit(unit)
    return unitToInstMap[unit]
end

local animMoving = {}
local animMining = {}
local animGetTool = {}
local animPutTool = {}
local animSpear = {}
local animSpearGuard = {}
local lastanims = {}
local equipped = {}
local onBack = {}

local function giveToolInsomnia(model)
    spawn(function()
        local victim = model.Handle.AlignPosition

        while model.Parent do
            --debug.profilebegin("Insomnia")
            victim.LimitsEnabled = true
            victim.LimitsEnabled = false
            --debug.profileend()

            --RunService.Stepped:Wait()
            wait(0.2)
        end
    end)
end

function ViewUnit.displayUnit(unit, oldModel)
    local model

    if unit.Type >= Unit.VILLAGER and unit.Type <= Unit.APPRENTICE then
        model = VillagerModel:Clone()
    elseif unit.Type >= Unit.SOLDIER and unit.Type <= Unit.SOLDIER then
        model = SoldierModel:Clone()
    end

    unitToInstMap[unit] = model
    instToUnitMap[model] = unit

    if oldModel then
        model.HumanoidRootPart.CFrame = oldModel.HumanoidRootPart.CFrame
        equipped[unit]:Destroy()
        equipped[unit] = nil

        for _, value in pairs(oldModel:GetChildren()) do
            if value:IsA("BasePart") and model:FindFirstChild(value.Name) then
                value.Anchored = true
                model[value.Name].CFrame = value.CFrame
                model[value.Name].Transparency = 1
            end
        end

        for _, value in pairs(model:GetChildren()) do
            if value:IsA("Accessory") then
                value.Handle.Transparency = 1
            end
        end

        spawn(function()
            local length = 240
            local fadelength = 240

            for i = 1, length+1 do
                local fadeVal = math.clamp((length - i) / fadelength, 0, 1)
                fadeVal = math.clamp(TweenService:GetValue(1 - fadeVal, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), 0, 1)
                fadeVal = math.clamp(((fadeVal*1.05)^50)/11.4, 0, 1)
                fadeVal = fadeVal > 0.1 and (fadeVal < 0.9 and fadeVal or 1) or 0

                for _, value in pairs(oldModel:GetChildren()) do
                    if value:IsA("BasePart") and value.Name ~= "HumanoidRootPart" and model:FindFirstChild(value.Name) then

                        value.CFrame = model[value.Name].CFrame
                        value.Transparency = fadeVal
                        model[value.Name].Transparency = 1 - fadeVal

                        if value.Name == "Head" then
                            value.face.Transparency = fadeVal
                        end

                    elseif value:IsA("Accessory") then
                        value.Handle.Transparency = math.clamp(fadeVal, 0, 1)
                    end
                end

                for _, value in pairs(model:GetChildren()) do
                    if value.Name == "Head" then
                        value.face.Transparency = 1 - fadeVal
                    elseif value:IsA("Accessory") then
                        value.Handle.Transparency = math.clamp(1 - fadeVal, 0, 1)
                    end
                end

                RunService.Heartbeat:Wait()
            end

            oldModel:Destroy()
        end)
    else
        model.HumanoidRootPart.CFrame = CFrame.new(Util.axialCoordToWorldCoord(unit.Position) + POSITION_OFFSET)
    end

    model.Parent = Workspace
    animMoving[model] = model.Humanoid:LoadAnimation(walkAnimation)
    animMining[model] = model.Humanoid:LoadAnimation(mineAnimation)
    animGetTool[model] = model.Humanoid:LoadAnimation(getBackAnim)
    animPutTool[model] = model.Humanoid:LoadAnimation(putBackAnim)
    animSpear[model] = model.Humanoid:LoadAnimation(spearAnim)
    animSpearGuard[model] = model.Humanoid:LoadAnimation(spearGuardAnim)

    ViewUnit.updateDisplay(unit)
    return model
end

local positionCache = {}
local gatherStatus = {}

function ViewUnit.updateDisplay(unit)
    local model = unitToInstMap[unit]

    if not model then
        return end

    if unit.Health < unit.MHealth then
        UIBase.displayObjectHealth(unit)
    end

    local onTile = currentWorld.Tiles[unit.Position.x ..":"..unit.Position.y]
    if onTile and onTile.Type == Tile.GATE then
        local gate = require(Client.ViewWorld).convertObjectToInst(onTile) --TODO: This

        gate.Bars.PrismaticConstraint.Attachment1 = gate.Up
        onTile.LastUnder = tick()

        delay(2, function()

            gate.Bars.PrismaticConstraint.Attachment1 = gate.Up
            onTile.LastUnder = tick()
            
            wait(1)

            if tick() - onTile.LastUnder >= 1 then
                gate.Bars.PrismaticConstraint.Attachment1 = gate.Down
            end
        end)
    end
    
    if model.Name == "Soldier" and unit.Type >= Unit.VILLAGER and unit.Type <= Unit.APPRENTICE then
        return ViewUnit.displayUnit(unit, model)
    elseif model.Name == "Villager" and unit.Type >= Unit.SOLDIER and unit.Type <= Unit.SOLDIER then
        return ViewUnit.displayUnit(unit, model)
    end

    local currentItem = equipped[unit]

    if not unit.HeldResource then
        unit.HeldResource = {Amount = 0}
    end

    if not gatherStatus[unit] then
        gatherStatus[unit] = unit.HeldResource.Amount
    end

    if gatherStatus[unit] ~= unit.HeldResource.Amount then
        model.HumanoidRootPart.StatusEmitter.Rate = math.max(0, (unit.HeldResource.Amount - gatherStatus[unit])/4)
        model.HumanoidRootPart.StatusEmitter.Size = NumberSequence.new((model.HumanoidRootPart.StatusEmitter.Rate/2)^1.5)
        gatherStatus[unit] = unit.HeldResource.Amount
    end

    local needsUpdate = false
    if unit.Type == Unit.MINER then

        if not currentItem or currentItem.Name ~= "Pickaxe" then

            needsUpdate = Assets.Pickaxe:Clone()
            model.HumanoidRootPart.StatusEmitter.Enabled = false
            model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.STONE
            model.HumanoidRootPart.StatusEmitter.Color = StatusCols.STONE
        end

    elseif unit.Type == Unit.LUMBERJACK then

        if not currentItem or currentItem.Name ~= "Axe" then

            needsUpdate = Assets.Axe:Clone()
            model.HumanoidRootPart.StatusEmitter.Enabled = false
            model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.WOOD
            model.HumanoidRootPart.StatusEmitter.Color = StatusCols.WOOD
        end
    elseif unit.Type == Unit.FARMER then

        if not currentItem or currentItem.Name ~= "Hoe" then

            needsUpdate = Assets.Hoe:Clone()
            model.HumanoidRootPart.StatusEmitter.Enabled = false
            model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.FOOD
            model.HumanoidRootPart.StatusEmitter.Color = StatusCols.FOOD
        end

    elseif unit.Type == Unit.APPRENTICE or unit.Type == Unit.SOLDIER then

        if not currentItem or currentItem.Name ~= "Spear" then

            needsUpdate = Assets.Spear:Clone()
            model.HumanoidRootPart.StatusEmitter.Enabled = false
        end
    end

    if needsUpdate then

        if currentItem then
            currentItem:Destroy()
        end

        currentItem = needsUpdate
        currentItem.Parent = model
        equipped[unit] = currentItem
        currentItem.CFrame = model.UpperTorso.ToolBackAttach.WorldCFrame

        if unit.State == Unit.UnitState.WORKING or unit.State == Unit.UnitState.TRAINING then
            currentItem.Handle.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
            currentItem.Handle.AlignOrientation.Attachment1 = model.LeftHand.LeftGripAttachment
            currentItem.SecondHandle.AlignPosition.Attachment1 = model.RightHand.RightGripAttachment
            onBack[model] = false
        else
            currentItem.Handle.AlignPosition.Attachment1 = model.UpperTorso.ToolBackAttach
            currentItem.Handle.AlignOrientation.Attachment1 = model.UpperTorso.ToolBackAttach
            onBack[model] = true
        end
        giveToolInsomnia(currentItem)
    end

    local actionAnim

    if unit.Type == Unit.APPRENTICE or unit.Type == Unit.SOLDIER then
        if unit.State == Unit.UnitState.TRAINING or unit.State == Unit.UnitState.COMBAT then
            actionAnim = animSpear[model]
        else
            actionAnim = animSpearGuard[model]
        end
    else
        actionAnim = animMining[model]
    end

    if currentItem then
        
        if ((unit.State == Unit.UnitState.WORKING or unit.State == Unit.UnitState.TRAINING or unit.State == Unit.UnitState.COMBAT or unit.State == Unit.UnitState.GUARDING)
            and unit.Target 
            and unit.Target == unit.Work)
            or unit.State == Unit.UnitState.COMBAT then

            if onBack[model] then

                onBack[model] = false
                animGetTool[model]:Play(1, 1)

                local ap = currentItem.Handle.AlignPosition
                local ao = currentItem.Handle.AlignOrientation
                local sap = currentItem.SecondHandle.AlignPosition

                delay(1, function()
                    if currentItem.Parent and model.Parent then
                        ap.Attachment1 = model.LeftHand.LeftGripAttachment
                        ao.Attachment1 = model.LeftHand.LeftGripAttachment

                        wait(1.53)
                        if ao.Attachment1 == model.LeftHand.LeftGripAttachment then
                            sap.Attachment1 = model.RightHand.RightGripAttachment
                        end
                    end
                end)
            end
        else
            if not onBack[model] then

                onBack[model] = true
                actionAnim:Stop(0.5)
                animPutTool[model]:Play(1, 1)
                lastanims[model] = animPutTool[model]
                currentItem.SecondHandle.AlignPosition.Attachment1 = nil

                delay(1.5, function()
                    if currentItem.Parent and model.Parent then
                        currentItem.Handle.AlignPosition.Attachment1 = model.UpperTorso.ToolBackAttach
                        currentItem.Handle.AlignOrientation.Attachment1 = model.UpperTorso.ToolBackAttach
                    end
                end)
            end
        end
    end

    if positionCache[unit] ~= unit.Position and model and unit.State ~= Unit.UnitState.COMBAT then
        positionCache[unit] = unit.Position
        local cpos = model.HumanoidRootPart.Position
        local pos = Util.axialCoordToWorldCoord(unit.Position) + POSITION_OFFSET

        local dir = (pos - cpos).unit
        local toTurn = cpos:Lerp(pos, 0.1)
        local turncf = CFrame.new(toTurn, pos)
        local targetcf = CFrame.new(pos, pos + dir)
        
        spawn(function()
            if dir.magnitude < 2 then
                TweenService:Create(model.HumanoidRootPart, fastTween, {CFrame = turncf}):Play()
                wait(0.25)
                TweenService:Create(model.HumanoidRootPart, tweenInfo, {CFrame = targetcf}):Play()
            end
        end)
    
    elseif unit.State == Unit.UnitState.COMBAT then
        local cpos = model.HumanoidRootPart.Position
        local pos = Util.axialCoordToWorldCoord(unit.Position) + POSITION_OFFSET
        local astr = Util.positionStringToVector(unit.Attack)
        local apos = Util.axialCoordToWorldCoord(astr) + POSITION_OFFSET

        local dir = (apos - cpos).unit
        local targetcf = CFrame.new(pos:Lerp(apos, 0.15), apos)

        TweenService:Create(model.HumanoidRootPart, tweenInfo, {CFrame = targetcf}):Play()
    end

    if unit.State == Unit.UnitState.IDLE then
        model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.IDLE
        model.HumanoidRootPart.StatusEmitter.Color = StatusCols.IDLE
        model.HumanoidRootPart.StatusEmitter.Rate = 1/3
        model.HumanoidRootPart.StatusEmitter.Size = NumberSequence.new(4)
        model.HumanoidRootPart.StatusEmitter.Enabled = true
        model.HumanoidRootPart.StatusEmitter.Lifetime = NumberRange.new(3)
    else
        model.HumanoidRootPart.StatusEmitter.Lifetime = NumberRange.new(1)
        model.HumanoidRootPart.StatusEmitter.Enabled = false
    end

    if unit.State == Unit.UnitState.MOVING then

        if not lastanims[model] or lastanims[model] ~= animMoving[model] then
            lastanims[model] = animMoving[model]
            animMoving[model]:Play(0.3, 1, 1.1)
        end

    elseif unit.State == Unit.UnitState.COMBAT then

        if not lastanims[model] or lastanims[model] ~= actionAnim then
            lastanims[model] = actionAnim
            actionAnim:Play(1)
        end

    elseif (unit.State == Unit.UnitState.WORKING or unit.State == Unit.UnitState.TRAINING or unit.State == Unit.UnitState.COMBAT or unit.State == Unit.UnitState.GUARDING) and unit.Target and unit.Target == unit.Work then

        animMoving[model]:Stop(3)
        
        if not lastanims[model] or lastanims[model] ~= actionAnim then
            lastanims[model] = actionAnim
            SoundManager.animSounds(currentItem, actionAnim)
            delay(math.random()+0.75, function() actionAnim:Play(1) end)
        end

        model.HumanoidRootPart.StatusEmitter.Enabled = not Unit.isMilitary(unit)

    elseif unit.State == Unit.UnitState.IDLE then
        animMoving[model]:Stop(0.5)
        animMining[model]:Stop()
        animSpear[model]:Stop()
        lastanims[model] = nil
    end
end

function ViewUnit.removeUnit(unit)
    local model = unitToInstMap[unit]
    
    if model then
        model:Destroy()
        unitToInstMap[unit] = nil
        instToUnitMap[model] = nil
    end
end

function ViewUnit.convertIdListToUnits(list)
    local units = {}

    for _, unit in pairs(list) do
        table.insert(units, currentWorld.Units[unit])
    end

    return units
end

function ViewUnit.convertIdListToInsts(list)
    if not list then
        return end

    local units = {}

    for _, unit in pairs(ViewUnit.convertIdListToUnits(list)) do
        local inst = ViewUnit.getInstFromUnit(unit)

        if inst then
            table.insert(units, inst)
        end
    end

    return units
end

function ViewUnit.provideUIBase(base)
    UIBase = base
end

spawn(autoUnload)

return ViewUnit