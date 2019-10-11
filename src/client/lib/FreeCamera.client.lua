------------------------------------------------
-- Roblox open source free camera script modified for more restricted use
-- Temporary for testing before camera script development

local player = game:GetService("Players")
while not player.LocalPlayer do player.Changed:wait() end
player = player.LocalPlayer
local camera = workspace.CurrentCamera

local RS  = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Spring = require(script.Parent:WaitForChild("Spring"))
local Maid = require(script.Parent:WaitForChild("Maid"))

local WasGuiVisible = {}
function ToggleGui(on)
	if not on then
		WasGuiVisible["PointsNotificationsActive"] = StarterGui:GetCore("PointsNotificationsActive")
		WasGuiVisible["BadgesNotificationsActive"] = StarterGui:GetCore("BadgesNotificationsActive")
		WasGuiVisible["Health"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
		WasGuiVisible["Backpack"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
		WasGuiVisible["PlayerList"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		WasGuiVisible["Chat"] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
	end

	local function GuiOn(name)
		if on == false then
			return false
		end
		if WasGuiVisible[name] ~= nil then
			return WasGuiVisible[name]
		end
		return true
	end

	StarterGui:SetCore("PointsNotificationsActive", GuiOn("PointsNotificationsActive"))
	StarterGui:SetCore("BadgesNotificationsActive", GuiOn("BadgesNotificationsActive"))

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, GuiOn("Health"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, GuiOn("Backpack"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, GuiOn("PlayerList"))
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, GuiOn("Chat"))
end

------------------------------------------------

local LVEL_GAIN = Vector3.new(1, 0.75, 1)
local RVEL_GAIN = Vector2.new(0.85, 1)/128
local FVEL_GAIN = -330
local DEADZONE = 0.125
local FOCUS_OFFSET = CFrame.new(0, 0, -16)

local DIRECTION_LEFT = 1
local DIRECTION_RIGHT = 2
local DIRECTION_FORWARD = 3
local DIRECTION_BACKWARD = 4
local DIRECTION_UP = 5
local DIRECTION_DOWN = 6

local KEY_MAPPINGS = {
	[DIRECTION_LEFT] = {Enum.KeyCode.A},
	[DIRECTION_RIGHT] = {Enum.KeyCode.D},
	[DIRECTION_FORWARD] = {Enum.KeyCode.W},
	[DIRECTION_BACKWARD] = {Enum.KeyCode.S},
	[DIRECTION_UP] = {Enum.KeyCode.E},
	[DIRECTION_DOWN] = {Enum.KeyCode.Q},
}

------------------------------------------------

local screenGuis = {}
local freeCamEnabled = false

local stateRot = Vector2.new()
local panDeltaGamepad = Vector2.new()
local panDeltaMouse = Vector2.new()

local velSpring = Spring.new(7/9, 1/10, 1, Vector3.new())
local rotSpring = Spring.new(7/9, 1/10, 1, Vector2.new())

local gp_x  = 0
local gp_z  = 0
local gp_l1 = 0
local gp_r1 = 0

local SpeedModifier = 1

------------------------------------------------

local function Clamp(x, min, max)
	return x < min and min or x > max and max or x
end

local function InputCurve(x)
	local s = math.abs(x)
	if s > DEADZONE then
		s = 0.255000975*(2^(2.299113817*s) - 1)
		return x > 0 and (s > 1 and 1 or s) or (s > 1 and -1 or -s)
	end
	return 0
end

------------------------------------------------

local function ProcessInput(input, processed)
	if _G.FreecamDisabled then return end 
    local userInputType = input.UserInputType
    
	if userInputType == Enum.UserInputType.Gamepad1 then
		local keycode = input.KeyCode
		if keycode == Enum.KeyCode.Thumbstick2 then
			local pos = input.Position
			panDeltaGamepad = Vector2.new(InputCurve(pos.y), InputCurve(-pos.x))*7
		elseif keycode == Enum.KeyCode.Thumbstick1 then
			local pos = input.Position
			gp_x = InputCurve(pos.x)
			gp_z = InputCurve(-pos.y)
		elseif keycode == Enum.KeyCode.ButtonL2 then
			gp_l1 = input.Position.z
		elseif keycode == Enum.KeyCode.ButtonR2 then
			gp_r1 = input.Position.z
		end
	end
end

local change = UIS.InputChanged:Connect(ProcessInput)
local ended = UIS.InputEnded:Connect(ProcessInput)
local began = UIS.InputBegan:Connect(ProcessInput)

------------------------------------------------

local function IsDirectionDown(direction)
	for i = 1, #KEY_MAPPINGS[direction] do
		if UIS:IsKeyDown(KEY_MAPPINGS[direction][i]) then
			return true
		end
	end
	return false
end

local UpdateFreecam do
	local dt = 1/60
	RS.RenderStepped:Connect(function(_dt)
		dt = _dt
	end)

	function UpdateFreecam()
		if _G.FreecamDisabled then return end 
		local camCFrame = camera.CFrame

		local kx = (IsDirectionDown(DIRECTION_RIGHT) and 1 or 0) - (IsDirectionDown(DIRECTION_LEFT) and 1 or 0)
		local ky = (IsDirectionDown(DIRECTION_UP) and 1 or 0) - (IsDirectionDown(DIRECTION_DOWN) and 1 or 0)
		local kz = (IsDirectionDown(DIRECTION_BACKWARD) and 1 or 0) - (IsDirectionDown(DIRECTION_FORWARD) and 1 or 0)
		local km = (kx * kx) + (ky * ky) + (kz * kz)
		if km > 1e-15 then
			km = ((UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) and 10 or 1)/math.sqrt(km)
			kx = kx * km
			ky = ky * km
			kz = kz * km
		end

		local dx = kx + gp_x
		local dy = ky + gp_r1 - gp_l1
		local dz = kz + gp_z

		velSpring.t = Vector3.new(dx, dy, dz) * SpeedModifier
		rotSpring.t = panDeltaMouse + panDeltaGamepad

		local dPos = velSpring:Update(dt) * LVEL_GAIN
		local dRot = rotSpring:Update(dt) * (RVEL_GAIN * math.tan(70 * math.pi/360) * 1)

		panDeltaMouse = Vector2.new()

		stateRot = stateRot + dRot
		stateRot = Vector2.new(Clamp(stateRot.x, -3/2, 3/2), stateRot.y)


		local lockedY = math.max(camCFrame.p.y, 5)

		local c = CFrame.new(camCFrame.p.x, lockedY, camCFrame.p.z) * CFrame.Angles(0, stateRot.y, 0) * CFrame.Angles(stateRot.x, 0, 0) * CFrame.new(dPos)

		camera.CFrame = c
		camera.Focus = c*FOCUS_OFFSET
	end
end

------------------------------------------------

local function Panned(input, processed)
	if _G.FreecamDisabled then return end 
	if not processed and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		panDeltaMouse = Vector2.new(-delta.y, -delta.x)
	end
end

------------------------------------------------

local function EnterFreecam()

	Maid:Mark(UIS.InputBegan:Connect(function(input, processed)
		if _G.FreecamDisabled then return end 

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local conn = UIS.InputChanged:Connect(Panned)
			repeat
				input = UIS.InputEnded:wait()
			until input.UserInputType == Enum.UserInputType.MouseButton2 or not freeCamEnabled
			panDeltaMouse = Vector2.new()
			panDeltaGamepad = Vector2.new()
			conn:Disconnect()
			if freeCamEnabled then
				UIS.MouseBehavior = Enum.MouseBehavior.Default
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			SpeedModifier = 0.5
		end
	end))

	Maid:Mark(UIS.InputEnded:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			SpeedModifier = 1
		end
	end))

	camera.CameraType = Enum.CameraType.Scriptable

	velSpring.t, velSpring.v, velSpring.x = Vector3.new(), Vector3.new(), Vector3.new()
	rotSpring.t, rotSpring.v, rotSpring.x = Vector2.new(), Vector2.new(), Vector2.new()

	local camCFrame = camera.CFrame
	local lookVector = camCFrame.lookVector.unit

	stateRot = Vector2.new(
		math.asin(lookVector.y),
		math.atan2(-lookVector.z, lookVector.x) - math.pi/2
	)
	panDeltaMouse = Vector2.new()

	local playerGui = player:WaitForChild("PlayerGui")
	for _, obj in next, playerGui:GetChildren() do
		if obj:IsA("ScreenGui") and obj.Enabled then
			obj.Enabled = false
			screenGuis[obj] = true
		end
	end
	if letterBoxEnabled then
		letterbox.Enabled = true
	end
	RS:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, UpdateFreecam)
	freeCamEnabled = true
end

--EnterFreecam()
