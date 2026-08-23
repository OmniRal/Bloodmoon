-- OmniRal

local CameraController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local New = require(ReplicatedStorage.Source.Pronghorn.New)
local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)
local DeviceController = require(StarterPlayer.StarterPlayerScripts.Source.General.DeviceController)

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Spring = require(ReplicatedStorage.Packages.Spring)

local CameraService = Remotes.Client.CameraService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TOP_DOWN_VECTOR_BASE = Vector3.new(0, 35, 15)
local TOP_DOWN_CHAR_OFFSET = Vector3.new(0, 0, 0)
local TOP_DOWN_MOUSE_OFFSET = 0.1
local TOP_DOWN_MOUSE_INDIVIDUAL_OFFSETS = {X = Vector2.new(0, 0), Y = Vector2.new(0.5, 0)}

local FIRST_PERSON_POSITION = Vector3.new(0, -0.5, 0)
local THIRD_PERSON_POSITION = Vector3.new(0, 2, 7)

-- Camera angle limits
local MAX_SIDE_ANGLE = 15
local MAX_VERTICAL_ANGLE_UP = 45
local MAX_VERTICAL_ANGLE_DOWN = 65

-- Input sensitivity
local MOUSE_SENSITIVITY_X = 0.1
local MOUSE_SENSITIVITY_Y = 0.15
local GAMEPAD_SENSITIVITY = 7
local GAMEPAD_DEADZONE = 0.25

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Core references
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Controller state
CameraController.Janitor = Janitor.new()
CameraController.CameraType = New.Var("Empty") -- "None", "TopDown", "FirstPerson", "ThirdPerson"
CameraController.RotateCharacter = true

-- Camera angles and input
local CameraAngleX = 0
local CameraAngleY = 0
local MouseDeltaX = 0
local MouseDeltaY = 0
local PreviousMouseDeltaX = 0
local PreviousMouseDeltaY = 0

-- Gamepad input
local GamepadX = 0
local GamepadY = 0

-- Shoulder positioning
local ShoulderPosition = THIRD_PERSON_POSITION
local ShoulderOffsetX = 0
local ShoulderOffsetY = 0

-- Camera transitions
local CameraLerp = {Start = nil, State = false, T = 0}
local CameraOrigin = {Focus = nil, RelativeOffset = nil, Distance = 0}

-- Character waist manipulation
local OriginWaistC0 = nil
local WaistOffset = {X = 0, Y = 0, Z = 0, XAngle = 0, ZAngle = 0}

-- Camera shake system
local CameraShake = Spring.new(Vector3.new(0, 0, 0))
CameraShake.Damper = 0.1
CameraShake.Speed = 25

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Handle character transparency for different camera modes
local function AdjustCharacterTransparency(Transparency: number)
	for _, Part in pairs(LocalPlayer.Character:GetChildren()) do
		if Part:IsA("BasePart") then
			if Part.Name == "Head" then
				-- Hide head and face in first person
				Part.LocalTransparencyModifier = Transparency
				if Part:FindFirstChild("face") then
					Part.face.LocalTransparencyModifier = Transparency
				end
			else
				-- Handle arms differently for first person view
				if not string.find(Part.Name, "Arm") and not string.find(Part.Name, "Hand") then
					Part.LocalTransparencyModifier = Transparency
				elseif string.find(Part.Name, "Arm") or string.find(Part.Name, "Hand") then
					--print(Part.Name, " ! ! !")
					local YSize, GoalSize = Part.Size.Y, 1
					if Transparency == 1 then
						GoalSize = 0.5
					end
					-- Note: This size change can cause character death - needs fixing
					Part.Size = Vector3.new(GoalSize, YSize, GoalSize)
				end
			end
		elseif Part:IsA("Hat") or Part:IsA("Accessory") then
			Part:FindFirstChild("Handle").LocalTransparencyModifier = Transparency
		end
	end
end

-- Restore mouse behavior when window regains focus
local function WindowFocus()
	local CameraType = CameraController.CameraType:Get()
	if CameraType == "FirstPerson" or CameraType == "ThirdPerson" then
		if DeviceController.CurrentDevice:Get() ~= "Mobile" then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		end
	end
end

-- Update camera angles based on input delta
local function UpdateCameraAngles(DeltaVector: Vector2)
	CameraAngleX -= (DeltaVector.X * MOUSE_SENSITIVITY_X)
	CameraAngleY = math.clamp(CameraAngleY - DeltaVector.Y * MOUSE_SENSITIVITY_Y, -MAX_VERTICAL_ANGLE_DOWN, MAX_VERTICAL_ANGLE_UP)

	-- Store deltas for shoulder offset calculations
	MouseDeltaX = DeltaVector.X
	MouseDeltaY = DeltaVector.Y
	PreviousMouseDeltaX = DeltaVector.X
	PreviousMouseDeltaY = DeltaVector.Y
end

-- Handle all input types (mouse, gamepad, touch)
local function HandleInput(_, State, InputObject)
	local CameraType = CameraController.CameraType:Get()
	if State == Enum.UserInputState.Change and (CameraType == "FirstPerson" or CameraType == "ThirdPerson") then
		local DeltaX = InputObject.Delta.X
		local DeltaY = InputObject.Delta.Y

		if InputObject.UserInputType == Enum.UserInputType.Gamepad1 then
			if InputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
				-- Process gamepad right stick input
				GamepadX = InputObject.Position.X
				GamepadY = -InputObject.Position.Y
				
				-- Apply deadzone
				if math.abs(GamepadX) <= GAMEPAD_DEADZONE then
					GamepadX = 0
				end
				if math.abs(GamepadY) <= GAMEPAD_DEADZONE then
					GamepadY = 0
				end

				-- Apply sensitivity
				GamepadX *= GAMEPAD_SENSITIVITY
				GamepadY *= GAMEPAD_SENSITIVITY
			end
		else
			-- Handle mouse/touch input
			UpdateCameraAngles(Vector2.new(DeltaX, DeltaY))
		end
	end
end

-- Calculate shoulder offset based on camera movement for dynamic feel
local function CalculateShoulderOffset(CameraType: string)
	local XOffsetLimits = NumberRange.new(0, 0)
	local YOffsetLimits = NumberRange.new(-0.25, 0.25)
	local YAdd = 1.5

	if CameraType == "ThirdPerson" then
		XOffsetLimits = NumberRange.new(-3, 3)
		YOffsetLimits = NumberRange.new(-0.5, 0.5)
		YAdd = 0
	end
	
	-- Smooth shoulder X offset based on mouse movement
	local DiffX = ((MouseDeltaX / 7) - ShoulderOffsetX)
	ShoulderOffsetX = math.clamp((DiffX / 10), -XOffsetLimits.Min, XOffsetLimits.Max)
	
	-- Limit Y offset near angle boundaries
	if CameraAngleY + YOffsetLimits.Max >= MAX_VERTICAL_ANGLE_UP then
		YOffsetLimits = NumberRange.new(0, YOffsetLimits.Max)
	elseif CameraAngleY - YOffsetLimits.Max <= -MAX_VERTICAL_ANGLE_DOWN then
		YOffsetLimits = NumberRange.new(YOffsetLimits.Min, 0)
	end

	-- Smooth shoulder Y offset based on mouse movement
	local DiffY = ((MouseDeltaY / 7) - ShoulderOffsetY)
	ShoulderOffsetY = math.clamp(ShoulderOffsetY + (DiffY / 10), YOffsetLimits.Min, YOffsetLimits.Max)
	
	return YAdd
end

-- Apply camera wobble when character is moving
local function ApplyCameraWobble(CameraType: string, Human: Humanoid, RootPart: BasePart)
	local ShakeMultiplier = 1
	
	if (Human.MoveDirection.Magnitude > 0) and (Human:GetState() == Enum.HumanoidStateType.Running) then
		local Offset
		
		if CameraType == "FirstPerson" then
			local XSpeed = Human.WalkSpeed / 1.5
			local ZSpeed = Human.WalkSpeed
			local ChargeSlow = 0
			
			Offset = Vector3.new(
				math.cos(os.clock() * XSpeed) * (PlayerInfo.MoveVector.X / (10 + ChargeSlow)),
				math.sin(os.clock() * ZSpeed) * (PlayerInfo.MoveVector.Z / (10 + ChargeSlow))
			) * 1
			
		elseif CameraType == "ThirdPerson" then
			local Velocity = RootPart.AssemblyLinearVelocity
			Offset = Vector3.new(
				math.cos(os.clock() * 8) * 0.1,
				math.sin(os.clock() * 8) * 0.1,
				0
			) * math.clamp(Velocity.Magnitude / Human.WalkSpeed, 1, 16)
		end

		Human.CameraOffset = Human.CameraOffset:Lerp(Offset, 0.25)
		ShakeMultiplier = 2 -- Increase shake when moving
	else
		Human.CameraOffset *= 0.9
	end
	
	return ShakeMultiplier
end

-- Calculate the main camera CFrame for first/third person modes
local function CalculateCameraCFrame()
	local CameraType = CameraController.CameraType:Get()
	local Human = PlayerInfo.Human
	local RootPart = PlayerInfo.Root

	if not Human or not RootPart then 
		return CFrame.new(0, 0, 0) 
	end

	-- Base camera rotation
	local BaseCFrame = CFrame.new(RootPart.CFrame.Position) 
		* CFrame.Angles(0, math.rad(CameraAngleX), 0) 
		* CFrame.Angles(math.rad(CameraAngleY), 0, 0)
	
	-- Calculate shoulder offset
	local YAdd = CalculateShoulderOffset(CameraType)
	
	-- Position camera at shoulder + offset
	local FromCFrame = BaseCFrame * CFrame.new(ShoulderPosition + Vector3.new(ShoulderOffsetX, ShoulderOffsetY + YAdd, 0))
	local ToCFrame = BaseCFrame * CFrame.new(Vector3.new(ShoulderPosition.X, ShoulderPosition.Y, -1000000))
	
	-- Apply camera wobble
	local ShakeMultiplier = ApplyCameraWobble(CameraType, Human, RootPart)

	-- Final camera calculations
	local CameraCFrame = CFrame.new(FromCFrame.Position, ToCFrame.Position)
	
	-- Apply camera shake
	CameraCFrame *= CFrame.new(
		math.cos(CameraShake.Position.X * 20) * (CameraShake.Position.X * 2) * ShakeMultiplier,
		math.sin(CameraShake.Position.Y * 20) * (CameraShake.Position.Y * 2) * ShakeMultiplier,
		0
	)
	
	-- Apply character wobble
	CameraCFrame *= CFrame.new(Human.CameraOffset.X, Human.CameraOffset.Y, Human.CameraOffset.Z)

	-- Decay mouse deltas
	MouseDeltaX *= 0.25
	MouseDeltaY *= 0.25

	return CameraCFrame
end

-- Start camera transition with smooth lerping
local function StartCameraTransition()
	CameraLerp.T = 0
	CameraLerp.Start = Camera.CFrame
	CameraLerp.State = true
end

-- Update character waist rotation based on camera angles
local function UpdateCharacterWaist()
	if not CameraController.RotateCharacter then
		if LocalPlayer.Character.UpperTorso:FindFirstChild("Waist") then
			LocalPlayer.Character.UpperTorso.Waist.C0 = OriginWaistC0
		end
		return
	end

	-- Smoothly angle the character's torso based on camera Y angle
	local GoalAngleX = math.rad(math.clamp(CameraAngleY, -MAX_VERTICAL_ANGLE_DOWN, MAX_VERTICAL_ANGLE_UP) / 1)
	local DiffX = (GoalAngleX - WaistOffset.XAngle)
	WaistOffset.XAngle += (DiffX / 5)

	-- Add side lean based on mouse movement
	local GoalAngleZ = -math.rad(math.clamp(PreviousMouseDeltaX, -MAX_SIDE_ANGLE, MAX_SIDE_ANGLE) / 2)
	local DiffZ = (GoalAngleZ - WaistOffset.ZAngle)
	WaistOffset.ZAngle += (DiffZ / 10)

	-- Apply waist rotation
	LocalPlayer.Character.UpperTorso.Waist.C0 = CFrame.new(WaistOffset.X, WaistOffset.Y, WaistOffset.Z) 
		* CFrame.Angles(WaistOffset.XAngle, 0, WaistOffset.ZAngle)
end

-- Rotate character to face camera direction
local function UpdateCharacterRotation()
	if not CameraController.RotateCharacter or LocalPlayer.Character:GetAttribute("Ragdoll") then return end
	if PlayerInfo.Dead or not PlayerInfo.Root then return end

	local CameraType = CameraController.CameraType:Get()
	
	if CameraType == "None" or CameraType == "TopDown" then
		-- Face mouse position in free camera or top down mode if value is true
		PlayerInfo.Root.CFrame = CFrame.new(
			PlayerInfo.Root.Position, 
			Vector3.new(Mouse.Hit.Position.X, PlayerInfo.Root.Position.Y, Mouse.Hit.Position.Z)
		)

	elseif CameraType == "FirstPerson" or CameraType == "ThirdPerson" then
		-- Face camera direction in first/third person
		PlayerInfo.Root.CFrame = CFrame.new(
			PlayerInfo.Root.Position,
			PlayerInfo.Root.Position + Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
		)
	end
end

-- Main heartbeat function - handles all camera updates
local function RunHeartbeat(DeltaTime: number)
	local CameraType = CameraController.CameraType:Get()
	
	-- Update camera position for first/third person modes
	if CameraType == "FirstPerson" or CameraType == "ThirdPerson" then
		if not CameraLerp.State then
			Camera.CFrame = CalculateCameraCFrame()
		end

		-- Handle gamepad input
		if DeviceController.CurrentDevice:Get() == "Gamepad" then
			UpdateCameraAngles(Vector2.new(GamepadX, GamepadY))
		end

		UpdateCharacterWaist()
		
		-- Decay previous mouse deltas
		PreviousMouseDeltaX *= 0.99
		PreviousMouseDeltaY *= 0.99

	elseif CameraType == "TopDown" then
		if not CameraLerp.State then
			if PlayerInfo.Root then
				local MouseOffset = Vector2.new(0, 0)
				if math.abs(TOP_DOWN_MOUSE_OFFSET) > 0 then
					local Center = Camera.ViewportSize / 2
					local X = -(Center.X - Mouse.X)
					local Y = -(Center.Y - Mouse.Y)
					local XMulti = (if X >= 0 then TOP_DOWN_MOUSE_INDIVIDUAL_OFFSETS.X.X else TOP_DOWN_MOUSE_INDIVIDUAL_OFFSETS.X.Y)
					local YMulti = (if Y >= 0 then TOP_DOWN_MOUSE_INDIVIDUAL_OFFSETS.Y.X else TOP_DOWN_MOUSE_INDIVIDUAL_OFFSETS.Y.Y)
					
					X = X * (math.abs(TOP_DOWN_MOUSE_OFFSET) + XMulti)
					Y = Y * (math.abs(TOP_DOWN_MOUSE_OFFSET) + YMulti)

					MouseOffset = Vector2.new(X, Y)
				end

				local FocusPoint = PlayerInfo.Root.Position + TOP_DOWN_CHAR_OFFSET + Vector3.new(MouseOffset.X / 10, 0, MouseOffset.Y / 10)

				Camera.CFrame = CFrame.new(FocusPoint + TOP_DOWN_VECTOR_BASE, FocusPoint)
			end
		end
	end

	-- Update character rotation for all modes
	UpdateCharacterRotation()

	-- Handle camera transitions
	if CameraLerp.State then
		CameraLerp.T = math.clamp(CameraLerp.T + DeltaTime * 4, 0, 1)

		local GoalCFrame
		if CameraType == "FirstPerson" or CameraType == "ThirdPerson" then
			GoalCFrame = CalculateCameraCFrame()
			Camera.CFrame = CameraLerp.Start:Lerp(CFrame.new(GoalCFrame.Position, (GoalCFrame * CFrame.new(0, 0, -10)).Position), CameraLerp.T)
		else
			-- Default camera position
			GoalCFrame = CFrame.new(
				(LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 7, 28)).Position,
				LocalPlayer.Character.HumanoidRootPart.Position
			)
			Camera.CFrame = CameraLerp.Start:Lerp(GoalCFrame, CameraLerp.T)
		end

		-- Finish transition
		if CameraLerp.T >= 1 then
			if CameraType == "FirstPerson" or CameraType == "ThirdPerson" then
				LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(
					LocalPlayer.Character.HumanoidRootPart.Position,
					Vector3.new(Camera.CFrame.Position.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, Camera.CFrame.Position.Z)
				) * CFrame.Angles(0, math.pi / 1.2, 0)
			else
				Camera.CameraType = Enum.CameraType.Custom
			end
			CameraLerp.State = false
		end
	end
end

-- Setup base camera for non-first/third person modes
local function SetupBaseCamera()
	RunService:UnbindFromRenderStep("BaseCamera")
	Camera.Focus = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 7, 21)
	
	RunService:BindToRenderStep("BaseCamera", Enum.RenderPriority.Camera.Value, function()
		local ShakeMultiplier = 1
		local ShakeCFrame = CFrame.new(
			math.cos(CameraShake.Position.X * 20) * (CameraShake.Position.X * 2) * ShakeMultiplier,
			math.sin(CameraShake.Position.Y * 20) * (CameraShake.Position.Y * 2) * ShakeMultiplier,
			0
		)
		Camera.CFrame = Camera.CFrame * ShakeCFrame
	end)
end

-- Clean up first/third person camera mode
local function CleanupFPSCamera()
	ContextActionService:UnbindAction("WindowFocus", WindowFocus, false, Enum.UserInputType.Focus)
	ContextActionService:UnbindAction("UpdateInput", HandleInput, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
	
	CameraController:SetMouse("Normal")
	StartCameraTransition()
	
	LocalPlayer.Character.Humanoid.AutoRotate = true
	if LocalPlayer.Character.UpperTorso:FindFirstChild("Waist") then
		LocalPlayer.Character.UpperTorso.Waist.C0 = OriginWaistC0
	end
end

-- Setup first/third person camera mode
local function SetupFPSCamera()
	ContextActionService:BindAction("WindowFocus", WindowFocus, false, Enum.UserInputType.Focus)
	ContextActionService:BindAction("UpdateInput", HandleInput, false, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch, Enum.UserInputType.Gamepad1)

	if DeviceController.CurrentDevice:Get() ~= "Mobile" then
		CameraController:SetMouse("Lock")
	end

	Camera.CameraType = Enum.CameraType.Scriptable

	-- Save camera origin for transitions
	CameraOrigin.Focus = PlayerInfo.Root.CFrame:PointToObjectSpace(Camera.Focus.Position)
	CameraOrigin.RelativeOffset = Camera.Focus:PointToObjectSpace(Camera.CFrame.Position)
	CameraOrigin.Distance = (Camera.Focus.Position - Camera.CFrame.Position).Magnitude
	
	StartCameraTransition()
	LocalPlayer.Character.Humanoid.AutoRotate = false
end

local function SetupTopDownCamera()
	Camera.CameraType = Enum.CameraType.Scriptable
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change camera field of view with smooth transition
function CameraController:ChangeFOV(TargetFOV: number, TweenTime: number, TweenStyle: Enum.EasingStyle, TweenDirection: Enum.EasingDirection)
	TweenService:Create(Camera, TweenInfo.new(TweenTime, TweenStyle, TweenDirection), {FieldOfView = TargetFOV}):Play()
end

-- Set mouse behavior and visibility
function CameraController:SetMouse(State: string)
	if State == "Normal" then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true

	elseif State == "Lock" then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end

-- Trigger camera shake effect
function CameraController:Shake(Speed: number, Damper: number, Power: Vector3)
	CameraShake.Speed = Speed
	CameraShake.Damper = Damper
	CameraShake:Impulse(Power)
end

-- Update camera settings from data
function CameraController:DataUpdate(Data: {})
	if not Data then return end
	-- Future: Handle camera side preference, sensitivity settings, etc.
end

-- Initialize camera for new character
function CameraController.SetCharacter()
	if LocalPlayer.Character then
		local Waist = LocalPlayer.Character:WaitForChild("UpperTorso"):WaitForChild("Waist")
		OriginWaistC0 = Waist.C0
		
		CameraController.SetCameraType("TopDown")
	end
end

-- Change camera mode (None, FirstPerson, ThirdPerson, FallDeath)
function CameraController.SetCameraType(CameraType: string?)
	local LastType = CameraController.CameraType:Get()
	
	CameraController.CameraType:Set(CameraType)
	RunService:UnbindFromRenderStep("BaseCamera")

	-- Setup heartbeat connection
	CameraController.Janitor:Add(RunService.Heartbeat:Connect(RunHeartbeat), "Disconnect", "CameraHeartbeat")
	
	if CameraType == "None" then
		CameraController.RotateCharacter = false
		Camera.CameraSubject = PlayerInfo.Human

		-- Clean up first/third person if coming from those modes
		if LastType == "FirstPerson" or LastType == "ThirdPerson" then
			CleanupFPSCamera()
		end

		SetupBaseCamera()
		AdjustCharacterTransparency(0)

	elseif CameraType == "FirstPerson" then
		CameraController.RotateCharacter = true
		ShoulderPosition = FIRST_PERSON_POSITION
		Camera.CameraSubject = PlayerInfo.Human

		SetupFPSCamera()
		AdjustCharacterTransparency(1) -- Hide character body

	elseif CameraType == "ThirdPerson" then
		CameraController.RotateCharacter = true
		ShoulderPosition = THIRD_PERSON_POSITION
		Camera.CameraSubject = PlayerInfo.Human

		SetupFPSCamera()
		AdjustCharacterTransparency(0) -- Show character body

	elseif CameraType == "TopDown" then
		SetupTopDownCamera()

	elseif CameraType == "FallDeath" then
		CameraController.RotateCharacter = false

		-- Clean up first/third person if coming from those modes
		if LastType == "FirstPerson" or LastType == "ThirdPerson" then
			CleanupFPSCamera()
		end

		SetupBaseCamera()
		Camera.CameraSubject = nil
		AdjustCharacterTransparency(0)
	end
end

-- Initialize the camera controller
function CameraController:Init()
	print("Camera Controller Init...")
end

-- Setup remote connections
function CameraController:Deferred()
	while true do
		task.wait()
		if not Remotes.Client.CameraService then continue end
		CameraService = Remotes.Client.CameraService
		break
	end

	CameraService.SetCameraType:Connect(function(CameraType: string?)
		if PlayerInfo.Dead and CameraType ~= "None" then return end 
		self:SetCameraType(CameraType)
	end)
	
	CameraService.CameraShake:Connect(function(Speed: number, Damper: number, Power: Vector3)
		self:Shake(Speed, Damper, Power)
	end)
end

return CameraController