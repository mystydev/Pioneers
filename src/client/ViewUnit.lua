local ViewUnit = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local ClientUtil = require(Client.ClientUtil)
local Util       = require(Common.Util)
local Unit       = require(Common.Unit)

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local clamp      = math.clamp
local UnitModel  = Assets.Dummy
local tweenInfo  = TweenInfo.new(2.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local fastTween  = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local walkAnimation = Instance.new("Animation")
walkAnimation.AnimationId = "rbxassetid://03090565308"
local mineAnimation = Instance.new("Animation")
mineAnimation.AnimationId = "rbxassetid://3090615222"
local putBackAnim = Instance.new("Animation")
putBackAnim.AnimationId = "rbxassetid://03090678702"
local getBackAnim = Instance.new("Animation")
getBackAnim.AnimationId = "rbxassetid://03090713020"

local StatusIds = {}
StatusIds.FOOD = "rbxassetid://3101321804"
StatusIds.WOOD = "rbxassetid://3101322014"
StatusIds.STONE = "rbxassetid://3101321954"
StatusIds.IDLE = "rbxassetid://3101321886"

local StatusCols = {}
StatusCols.FOOD = ColorSequence.new(Color3.fromRGB(255, 236, 179))
StatusCols.WOOD = ColorSequence.new(Color3.fromRGB(46, 125, 50))
--StatusCols.STONE = ColorSequence.new(Color3.fromRGB(2, 136, 209))
StatusCols.STONE = ColorSequence.new(Color3.fromRGB(155, 155, 155))
StatusCols.IDLE = ColorSequence.new(Color3.fromRGB(171, 8, 0))

local unitToInstMap = {}
local instToUnitMap = {}

local modelSizeOffset = Vector3.new(2, 5, 2)

local function unload(tile, model) --TODO: fully unload from memory
    instToUnitMap[model] = nil
    unitToInstMap[model] = nil
    model:Destroy()
end

local function autoUnload() --TODO: fully unload from memory
    local getPos = ClientUtil.getPlayerPosition
    local dist
    
    repeat
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
    until false
end

function ViewUnit.getUnitFromInst(inst)
    return instToUnitMap[inst] or instToUnitMap[inst.Parent]
end

function ViewUnit.getInstFromUnit(unit)
    return unitToInstMap[unit]
end

local animMoving = {}
local animMining = {}
local animGetTool = {}
local animPutTool = {}
local lastanims = {}

function ViewUnit.displayUnit(unit)
    local model = UnitModel:Clone()

    unitToInstMap[unit] = model
    instToUnitMap[model] = unit

    model.HumanoidRootPart.CFrame = CFrame.new(Util.axialCoordToWorldCoord(unit.Position) + Vector3.new(0, 4, 0))
    model.Parent = Workspace

    animMoving[model] = model.Humanoid:LoadAnimation(walkAnimation)
    animMining[model] = model.Humanoid:LoadAnimation(mineAnimation)
    animGetTool[model] = model.Humanoid:LoadAnimation(getBackAnim)
    animPutTool[model] = model.Humanoid:LoadAnimation(putBackAnim)
end

local positionCache = {}
local equipped = {}
local onBack = {}
local gatherStatus = {}

function ViewUnit.updateDisplay(unit)
    local model = unitToInstMap[unit]

    local currentItem = equipped[unit]

    if not unit.HeldResource then
        unit.HeldResource = {Amount = 0}
    end

    if not gatherStatus[unit] then
        gatherStatus[unit] = unit.HeldResource.Amount
    end

    if gatherStatus[unit] ~= unit.HeldResource.Amount then
        model.HumanoidRootPart.StatusEmitter.Rate = math.max(0, (unit.HeldResource.Amount - gatherStatus[unit])/2)
        model.HumanoidRootPart.StatusEmitter.Size = NumberSequence.new((model.HumanoidRootPart.StatusEmitter.Rate/2)^1.5)
        gatherStatus[unit] = unit.HeldResource.Amount
    end

    if unit.Type == Unit.MINER then

        if not currentItem or currentItem.Name ~= "Pickaxe" then
            if currentItem then
                currentItem:Destroy()
            end

            local p = Assets.Pickaxe:Clone()
            p.Parent = model
            p.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
            p.AlignOrientation.Attachment1 = model.LeftHand.LeftGripAttachment
    
            equipped[unit] = p
            currentItem = p
            model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.STONE
            model.HumanoidRootPart.StatusEmitter.Color = StatusCols.STONE
        end

    elseif unit.Type == Unit.LUMBERJACK then

        if not currentItem or currentItem.Name ~= "Axe" then
            if currentItem then
                currentItem:Destroy()
            end

            local p = Assets.Axe:Clone()
            p.Parent = model
            p.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
            p.AlignOrientation.Attachment1 = model.LeftHand.LeftGripAttachment
    
            equipped[unit] = p
            currentItem = p
            model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.WOOD
            model.HumanoidRootPart.StatusEmitter.Color = StatusCols.WOOD
        end
    elseif unit.Type == Unit.FARMER then

        if not currentItem or currentItem.Name ~= "Hoe" then
            if currentItem then
                currentItem:Destroy()
            end

            local p = Assets.Hoe:Clone()
            p.Parent = model
            p.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
            p.AlignOrientation.Attachment1 = model.LeftHand.LeftGripAttachment
    
            equipped[unit] = p
            currentItem = p
            model.HumanoidRootPart.StatusEmitter.Texture = StatusIds.FOOD
            model.HumanoidRootPart.StatusEmitter.Color = StatusCols.FOOD
        end
    end

    if currentItem then

        if unit.State == Unit.UnitState.WORKING then
            if onBack[model] then
                onBack[model] = false
                animGetTool[model]:Play(0.5)
                spawn(function()
                    wait(1)
                    currentItem.AlignPosition.Attachment1 = model.LeftHand.LeftGripAttachment
                    currentItem.AlignOrientation.Attachment1 = model.LeftHand.LeftGripAttachment

                    animGetTool[model].Stopped:Wait()
                    currentItem.AlignPosition.RigidityEnabled = false
                    currentItem.AlignPosition.RigidityEnabled = true
                end)
            end
        else
            if not onBack[model] then
                onBack[model] = true
                animPutTool[model]:Play(0.5)
                spawn(function()
                    wait(1)
                    currentItem.AlignPosition.Attachment1 = model.UpperTorso.ToolBackAttach
                    currentItem.AlignOrientation.Attachment1 = model.UpperTorso.ToolBackAttach

                    animPutTool[model].Stopped:Wait()
                    currentItem.AlignPosition.RigidityEnabled = false
                    currentItem.AlignPosition.RigidityEnabled = true
                end)
            end
        end
    end

    if positionCache[unit] ~= unit.Position and model then
        positionCache[unit] = unit.Position
        local cpos = model.HumanoidRootPart.Position
        local pos = Util.axialCoordToWorldCoord(unit.Position) + Vector3.new(0, 4, 0)
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
        animMining[model]:Stop(0.5)
        if lastanims[model] ~= animMoving[model] then
            animMoving[model]:Play(0.5)
            lastanims[model] = animMoving[model]
        end
    elseif unit.State == Unit.UnitState.WORKING then
        animMoving[model]:Stop(0.5)
        if lastanims[model] ~= animMining[model] then
            animMining[model]:Play(0.5)
            lastanims[model] = animMining[model]
        end
        model.HumanoidRootPart.StatusEmitter.Enabled = true
    else
        animMoving[model]:Stop(0.5)
        animMining[model]:Stop(0.5)
        lastanims[model] = nil
    end

end

spawn(autoUnload)

return ViewUnit