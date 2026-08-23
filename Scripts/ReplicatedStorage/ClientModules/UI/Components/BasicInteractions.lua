-- OmniRal

local BasicInteractions = {}

-- Helps set up the most common UI interactions; such as basic buttons and close buttons 

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UIInfo = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CROSS_BASE_SIZE = UDim2.fromScale(0.8, 0.8)
local CROSS_HOVER_SIZE = UDim2.fromScale(0.9, 0.9)
local CROSS_PRESS_SIZE = UDim2.fromScale(0.5, 0.5)

local STANDARD_2_HOVER_MULTIPLIER = 1.1
local STANDARD_2_PRESSED_MULTIPLIER = 0.6

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes / Signals
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Camera = Workspace.CurrentCamera

local AnimTime = UIInfo.BaseAnimTime

local UISounds = ReplicatedStorage.Assets.UISounds

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function UpdateCloseButtonAnimations(Button: ImageButton, Cross: ImageLabel)
	local Hover, Pressed = Button:GetAttribute("Hover"), Button:GetAttribute("Pressed")
	local GoalSize = CROSS_BASE_SIZE

	if Hover and not Pressed then
		GoalSize = CROSS_HOVER_SIZE
	elseif Hover and Pressed then
		GoalSize = CROSS_PRESS_SIZE
	end

	TweenService:Create(Cross, TweenInfo.new(AnimTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = GoalSize}):Play()
end

local function UpdateStandardButtonAnimations(Button: any, ToggleFromActivation: boolean?)
	local On, Hover, Pressed, Locked = Button.Click:GetAttribute("On"), Button.Click:GetAttribute("Hover"), Button.Click:GetAttribute("Pressed"), Button.Click:GetAttribute("Locked")
	local GoalSize = UDim2.fromScale(0.8, 0.8)
	local GoalColor = ColorPalette.JetWhite.RGB
	local GoalTransparency = if Locked then 0.75 else 0

	if ToggleFromActivation and On then
		GoalColor = ColorPalette.MidGrey.RGB
	end

	if Hover and not Pressed then
		GoalSize = UDim2.fromScale(0.9, 0.9)
	elseif Pressed then
		GoalSize = UDim2.fromScale(0.5, 0.5)
	end

	Button.Frame.Size = GoalSize
	Button.GroupColor3 = GoalColor
	Button.GroupTransparency = GoalTransparency
end

local function UpdateStandardButtonAnimations_2(Button: ImageButton, Icon: ImageLabel, ToggleFromActivation: boolean?, BaseSize: UDim2, HoverSize: UDim2, PressedSize: UDim2)
	local Hover, Pressed, Locked = Button:GetAttribute("Hover"), Button:GetAttribute("Pressed"), Button:GetAttribute("Locked")

	if Hover and not Pressed and not Locked then
		TweenService:Create(Icon, TweenInfo.new(AnimTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = HoverSize}):Play()

	elseif (not Hover and not Pressed) or (Locked) then
		TweenService:Create(Icon, TweenInfo.new(AnimTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = BaseSize}):Play()

	elseif Pressed and not Locked then
		TweenService:Create(Icon, TweenInfo.new(AnimTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = PressedSize}):Play()

	end
	
	Icon.ImageTransparency = if Locked then 0.75 else 0

	if ToggleFromActivation then return end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Add basic states for a button
-- @Button = The button that should have the interaction
-- @ToggleFromActivation = When true, the buttons' ON attribute will toggle true and false when pressed
-- @ControlOnIndependently = The buttons "On" attribute won't automatically update from the activated function here; the user can then control this from another script
-- @DraggableElement = Which, if any, UI should be draggable. Often the draggable element will be the same as the button, but kept option for it to be something else
-- @DragCondition = Runs this to make sure the element is allowed to be dragged
-- @StartDrag = Runs once at the beginning of the drag
-- @Dragging = Runs while the element is being dragged
-- @StopDrag = Runs once at the end of the drag
-- @DragDelay = How long to wait before start dragging
function BasicInteractions.AddButton(
	Button: GuiButton, 
	ToggleFromActivation: boolean?,
	ControlOnIndependently: boolean?,
	DraggableElement: any?,
	DragCondition: (() -> (boolean))?,
	StartDrag: ((any) -> ())?,
	Dragging: ((UDim2, Vector3, Vector3) -> ())?,
	StopDrag: ((GuiObject) -> ())?,
	DragDelay: number?
)
	if not Button then warn("Button missing!"); return end
	
	local InputHandler: RBXScriptConnection?
	local DragHandler: RBXScriptConnection?
	
	local DragDelayThread: thread
	local ElementPosition: UDim2
	local DragStart: Vector3
	
	Button:SetAttribute("On", false) -- Active / Inactive state
	Button:SetAttribute("Hover", false)
	Button:SetAttribute("Pressed", false) -- When the player is holding down on the button
	Button:SetAttribute("Locked", false) -- When the button should not be interactable AT ALL
	
	Button.Activated:Connect(function()
		if Button:GetAttribute("Locked") then return end
		
		if ControlOnIndependently then return end -- Handle changing the on state from outside
		if ToggleFromActivation then
			Button:SetAttribute("On", not Button:GetAttribute("On")) -- Toggle it
		else
			if Button:GetAttribute("On") then return end
			Button:SetAttribute("On", true) -- Turn it on only
		end
	end)
	
	Button:GetAttributeChangedSignal("Locked"):Connect(function()
		if not Button:GetAttribute("Locked") then return end
		
		Button:SetAttribute("On", false)
		Button:SetAttribute("Hover", false)
		Button:SetAttribute("Pressed", false)
	end)
	
	Button.MouseEnter:Connect(function() 
		if Button:GetAttribute("Locked") then return end 
		Button:SetAttribute("Hover", true) 
	end)
	Button.MouseLeave:Connect(function() 
		if Button:GetAttribute("Locked") then return end 
		Button:SetAttribute("Hover", false) 
	end)
	
	Button.InputBegan:Connect(function(Input: InputObject)
		if Button:GetAttribute("Locked") then return end
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
		
		if InputHandler then InputHandler:Disconnect() end
		
		Button:SetAttribute("Pressed", true)
		
		local function BeginDraggingElement()
			Button:SetAttribute("Dragging", true)
			DragStart = Input.Position
			ElementPosition = DraggableElement.Position
			
			DragHandler = UserInputService.InputChanged:Connect(function(MoveInput: InputObject)
				if MoveInput.UserInputType ~= Enum.UserInputType.MouseMovement and MoveInput.UserInputType ~= Enum.UserInputType.Touch then return end
				if not Dragging or not Button:GetAttribute("Dragging") then return end
				Dragging(ElementPosition, DragStart, MoveInput.Position)
			end)
			
			if not StartDrag then return end
			StartDrag(DraggableElement)
		end
		
		-- Disconnect when the player releases the button
		InputHandler = Input.Changed:Connect(function()
			if Input.UserInputState ~= Enum.UserInputState.End then return end

			-- Stop input
			if InputHandler then InputHandler:Disconnect(); InputHandler = nil end
			if DragHandler then warn("Stopping!") DragHandler:Disconnect(); DragHandler = nil; Button:SetAttribute("Dragging", false); end
			if DraggableElement and StopDrag then StopDrag(DraggableElement) end

			InputHandler = nil
			Button:SetAttribute("Pressed", false)
		end)
		
		-- Handle dragging start
		if DraggableElement then
			if DragCondition and not DragCondition() then return end
			if not DragDelay then
				BeginDraggingElement()
				
			else
				if DragDelayThread then
					task.cancel(DragDelayThread)
				end
				
				DragDelayThread = task.delay(DragDelay, function()
					BeginDraggingElement()
				end)
			end
		end
	end)
end

-- Connect a specific function that updates the visuals of a button when it's hover, pressed or on attributes change
-- @Button = Which button to connect it to
-- @Fn = The function to use
-- @Ingore(x) = Ignore a specific attribute
function BasicInteractions.ConnectFXInteractionsFN(Button: GuiButton, Fn: (...any) -> (...any), IgnoreHover: boolean?, IgnorePressed: boolean?, IgnoreOn: boolean?, IgnoreLocked: boolean?, ...)
	if not Button or not Fn then return end

	local Other = {...}

	if not IgnoreHover then
		Button:GetAttributeChangedSignal("Hover"):Connect(function()
			if Other then Fn(Button, unpack(Other)) else Fn(Button) end
		end)
	end

	if not IgnorePressed then
		Button:GetAttributeChangedSignal("Pressed"):Connect(function()
			if Other then Fn(Button, unpack(Other)) else Fn(Button) end
		end)
	end

	if not IgnoreOn then
		Button:GetAttributeChangedSignal("On"):Connect(function()
			if Other then Fn(Button, unpack(Other)) else Fn(Button) end
		end)
	end

	if not IgnoreLocked then
		Button:GetAttributeChangedSignal("Locked"):Connect(function()
			if Other then Fn(Button, unpack(Other)) else Fn(Button) end
		end)
	end
end

-- To quickly hook up the standard close "X" button for the UI
function BasicInteractions.AddCloseButton(Button: ImageButton, CloseFn: () -> (), SkipPositioning: boolean?)
	if not Button then warn("Close button is missing!"); return end
	if not CloseFn then warn ("Close function is missing!"); return end
	
	local Cross = Button:FindFirstChild("Cross")
	if not Cross then warn("Cross image insode of close button is missing!"); return end
	
	BasicInteractions.AddButton(Button)
	
	Button:GetAttributeChangedSignal("Hover"):Connect(function()
		UpdateCloseButtonAnimations(Button, Cross)
		if Button:GetAttribute("Hover") then
			UISounds.CloseButtonHover:Play()
		end
	end)
	
	Button:GetAttributeChangedSignal("Pressed"):Connect(function()
		UpdateCloseButtonAnimations(Button, Cross)
		if Button:GetAttribute("Pressed") then
			UISounds.CloseButtonPress:Play()
		end
	end)
	
	Button.Activated:Connect(function()
		if Button:GetAttribute("Locked") then return end
		CloseFn()
	end)
	
	local Size = Camera.ViewportSize.X / 25
	Button.Size = UDim2.fromOffset(Size, Size)
	
	if SkipPositioning then return end
	Button.Position = UDim2.new(1, -Size / 20, 0, 0)
end

function BasicInteractions.AddStandardButton(Button: any, Fn: () -> (), ToggleFromActivation: boolean?)
	if not Button then return end
	
	BasicInteractions.AddButton(Button.Click, ToggleFromActivation)
	
	Button.Click:GetAttributeChangedSignal("Hover"):Connect(function()
		UpdateStandardButtonAnimations(Button, ToggleFromActivation)
		if Button.Click:GetAttribute("Hover") then
			--UISounds.StandardButtonHover:Play()
		end
	end)
	
	Button.Click:GetAttributeChangedSignal("Pressed"):Connect(function()
		UpdateStandardButtonAnimations(Button, ToggleFromActivation)
		if Button.Click:GetAttribute("Pressed") then
			--UISounds.StandardButtonPress:Play()
		end
	end)
	
	if ToggleFromActivation then
		Button.Click:GetAttributeChangedSignal("On"):Connect(function()
			UpdateStandardButtonAnimations(Button, ToggleFromActivation)
		end)
	end
	
	Button.Click:GetAttributeChangedSignal("Locked"):Connect(function()
		UpdateStandardButtonAnimations(Button, ToggleFromActivation)
	end)
	
	Button.Click.Activated:Connect(function()
		if Button.Click:GetAttribute("Locked") then return end
		Fn()
	end)
end

function BasicInteractions.AddStandardButton_2(Button: any, Fn: () -> ()?, ToggleFromActivation: boolean?, HoverMultiplier: number?, PressedMultiplier: number?)
	if not Button then warn("Standard button 2 missing!"); return end
	
	local Icon = Button.Parent:FindFirstChild("Icon") or Button:FindFirstChild("Icon") :: ImageLabel
	if not Icon then warn("Icon missing in standard button 2"); return end
	
	local BaseSize = UDim2.fromScale(Icon.Size.X.Scale, Icon.Size.Y.Scale)
	
	local HoverSize = UDim2.fromScale(Icon.Size.X.Scale * (HoverMultiplier or STANDARD_2_HOVER_MULTIPLIER), 
		Icon.Size.Y.Scale * (HoverMultiplier or STANDARD_2_HOVER_MULTIPLIER))
	
	local PressedSize = UDim2.fromScale(Icon.Size.X.Scale * (PressedMultiplier or STANDARD_2_PRESSED_MULTIPLIER), 
		Icon.Size.Y.Scale * (PressedMultiplier or STANDARD_2_PRESSED_MULTIPLIER))
	
	BasicInteractions.AddButton(Button, ToggleFromActivation)	
	
	Button:GetAttributeChangedSignal("Hover"):Connect(function()
		UpdateStandardButtonAnimations_2(Button, Icon, ToggleFromActivation, BaseSize, HoverSize, PressedSize)
		if Button:GetAttribute("Hover") then
			UISounds.StandardButtonHover_2:Play()
		end
	end)

	Button:GetAttributeChangedSignal("Pressed"):Connect(function()
		UpdateStandardButtonAnimations_2(Button, Icon, ToggleFromActivation, BaseSize, HoverSize, PressedSize)
		if Button:GetAttribute("Pressed") then
			UISounds.StandardButtonPress_2:Play()
		end
	end)
	
	if ToggleFromActivation then
		Button:GetAttributeChangedSignal("On"):Connect(function()
			if Fn then Fn() end
			UpdateStandardButtonAnimations_2(Button, Icon, ToggleFromActivation, BaseSize, HoverSize, PressedSize)
		end)
	end
	
	Button:GetAttributeChangedSignal("Locked"):Connect(function()
		UpdateStandardButtonAnimations_2(Button, Icon, ToggleFromActivation, BaseSize, HoverSize, PressedSize)
	end)

	Button.Activated:Connect(function()
		if Button:GetAttribute("Locked") then return end
		if Fn then Fn() end
	end)
end

return BasicInteractions