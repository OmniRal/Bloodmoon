-- OmniRal

local ToggleSwitch = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UIInfo = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)
local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ON_BASE_COLOR = Color3.fromRGB(220, 255, 220)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- A reference for all the types of toggle switches
local ToggleStates: {
	[string]: {State: boolean, Switches: {ImageButton}}
} = {}

local AnimTime = UIInfo.BaseAnimTime

local UISounds = ReplicatedStorage.Assets.UISounds

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- The button slidey animation
local function UpdateSwitchVisuals(_, Switch: any)
	local On, Hover, Pressed = Switch.Button:GetAttribute("On"), Switch.Button:GetAttribute("Hover"), Switch.Button:GetAttribute("Pressed") 

	local GoalPosition, GoalColor = UDim2.fromScale(0.25, 0.5), ColorPalette.DarkGrey.RGB
	if On then
		GoalPosition = UDim2.fromScale(0.75, 0.5)
		GoalColor = ColorPalette.OmniBlotRed2.RGB
	end

	if not Hover and not Pressed then
		Switch.Knob.Size = UDim2.fromScale(0.7, 0.7)
	elseif Hover and not Pressed then
		Switch.Knob.Size = UDim2.fromScale(0.8, 0.8)
	elseif Pressed then
		Switch.Knob.Size = UDim2.fromScale(0.6, 0.6)
	end

	if On == Switch:GetAttribute("LastOn") then return end

	Switch:SetAttribute("LastOn", On)
	TweenService:Create(Switch.Knob, TweenInfo.new(AnimTime / 2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = GoalPosition, BackgroundColor3 = GoalColor}):Play()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Add a swtich to have functionality
function ToggleSwitch.AddSwitch(Switch: any, Fn: () -> ()?, ControlOnIndependently: boolean?)
	if not Switch then warn ("Switch is missing!"); return end
	if not Fn then warn("Switch function is missing!"); return end
	
	local Name = string.gsub(Switch.Name, "ToggleSwitch_", "")
	
	if not ToggleStates[Name] then
		ToggleStates[Name] = {
			State = false,
			Switches = {}
		}
	end
	
	table.insert(ToggleStates[Name].Switches, Switch)
	Switch:SetAttribute("On", false)
	Switch:SetAttribute("LastOn", false)

	BasicInteractions.AddButton(Switch.Button, true, true)
	BasicInteractions.ConnectFXInteractionsFN(Switch.Button, UpdateSwitchVisuals, nil, nil, nil, nil, Switch)
	
	Switch.Button.Activated:Connect(function()
		if ControlOnIndependently then Fn(); return end
		ToggleStates[Name].State = not ToggleStates[Name].State
		
		-- Make sure all the UI switches associated with this value are updated
		for _, OtherSwitch in ToggleStates[Name].Switches do
			if not OtherSwitch then continue end
			Switch:SetAttribute("On", ToggleStates[Name].State)
			UpdateSwitchVisuals(nil, Switch)
		end
		
		--[[if ToggleStates[Name].State then
			UISounds.ToggleSwitch_On:Play()
		else
			UISounds.ToggleSwitch_Off:Play()
		end]]

		Fn()
	end)

	if not ControlOnIndependently then return end
	Switch:GetAttributeChangedSignal("On"):Connect(function()
		ToggleStates[Name].State = Switch:GetAttribute("On")
		
		for _, OtherSwitch in ToggleStates[Name].Switches do
			if not OtherSwitch then continue end
			if OtherSwitch == Switch then continue end
			Switch:SetAttribute("On", ToggleStates[Name].State)
			UpdateSwitchVisuals(nil, Switch)
		end
	end)
end

return ToggleSwitch