local SoundManager = {}
local Sounds = game.ReplicatedStorage.Pioneers.Assets.Sound

local TweenService = game:GetService("TweenService")


local masterGroup = Instance.new("SoundGroup", workspace)
masterGroup.Volume = 1


local FocusMuteVals = {
    on = {
        HighGain = -10,
        MidGain = -17,
        LowGain = -2,
    },
    off = {
        HighGain = 0,
        MidGain = 0,
        LowGain = 0,
    },
    info = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
}

function SoundManager.init()
    spawn(SoundManager.newBGM)
    local focusMuteMod = Sounds.Mods.FocusMute:Clone()
    focusMuteMod.Parent = masterGroup
end

function SoundManager.newBGM()
    local bgm = Sounds.BGM:GetChildren()
    local i = math.random(1, #bgm)
    music = bgm[i]:Clone()
    music.Parent = masterGroup
    music.SoundGroup = masterGroup
    music.Playing = true

    music.Ended:Wait()
    music:Destroy()
    SoundManager.newBGM()
end

function SoundManager.tempGlobal(sound)
    sound.Parent = masterGroup
    sound:Destroy()
end

function SoundManager.tempWorld(sound, inst)
    sound.Parent = inst
    sound:Destroy()
end

function SoundManager.pullFocus()
    SoundManager.tempGlobal(Sounds.Effects.SoftSelect:Clone())
    TweenService:Create(masterGroup.FocusMute, FocusMuteVals.info, FocusMuteVals.on):Play()
end

function SoundManager.endFocus()
    TweenService:Create(masterGroup.FocusMute, FocusMuteVals.info, FocusMuteVals.off):Play()
end

function SoundManager.success()
    SoundManager.tempGlobal(Sounds.Effects.Success:Clone())
end

function SoundManager.initiatePlace()
    local effect = Sounds.Effects.InitiatePlace:Clone()
    effect.Parent = masterGroup
    effect.Playing = true
    delay(1, function() effect:Destroy() end)
end

function SoundManager.highlight()
    SoundManager.tempGlobal(Sounds.Effects.Highlight:Clone())
end

function SoundManager.animSounds(inst, anim)
    spawn(function()
        local hitSignal = anim:GetMarkerReachedSignal("Hit")
        local sound = Sounds.Effects.HollowHit:Clone()
        sound.Archivable = false
        sound.Parent = inst
        
        while anim do
            hitSignal:Wait()
            sound:Play()
        end

        sound:Destroy()
    end)
end

return SoundManager