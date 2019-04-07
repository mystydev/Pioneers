local ViewSelection = {}

local Common = game.ReplicatedStorage.Pioneers.Common

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local cam = Instance.new("Camera")
local blur = Instance.new("BlurEffect")
local desaturate = Instance.new("ColorCorrectionEffect")
local viewport
local managedinsts = {}
local numinst = 0

local tweenSlow = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenFast = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

blur.Size = 0
--blur.Enabled = false
desaturate.Saturation = 0
--desaturate.Enabled = false

local function updateCamera()
    while true do


        RunService.RenderStepped:Wait()
    end
end 

function ViewSelection.createDisplay()

    local gui = Instance.new("ScreenGui", player.PlayerGui)
    gui.Name = "ViewSelection"

    viewport = Instance.new("ViewportFrame", gui)
    viewport.Size = UDim2.new(1, 0, 1, 36)
    viewport.Position = UDim2.new(0, 0, 0, -36)
    viewport.BackgroundTransparency = 1


    blur.Parent = Lighting
    desaturate.Parent = Lighting
    viewport.CurrentCamera = workspace.CurrentCamera
end

function ViewSelection.addInst(inst)
    inst.Parent = viewport
    numinst = numinst + 1

    TweenService:Create(blur, tweenSlow, {Size = 20}):Play()
    TweenService:Create(desaturate, tweenSlow, {Saturation = -0.5}):Play()
end

function ViewSelection.removeInst(inst)
    inst.Parent = workspace
    numinst = numinst - 1

    if numinst <= 0 then
        TweenService:Create(blur, tweenFast, {Size = 0}):Play()
        TweenService:Create(desaturate, tweenFast, {Saturation = 0}):Play()
    end
end

function ViewSelection.removeDisplay()
    Roact.unmount(displayHandle)
end

return ViewSelection