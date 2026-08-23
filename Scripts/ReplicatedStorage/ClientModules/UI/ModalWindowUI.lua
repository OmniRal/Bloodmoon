-- OmniRal

local ModalWindowUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ON_POSITION = UDim2.fromScale(0.5, 0.5)
local OFF_POSITION = UDim2.fromScale(0.5, 0.6)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ModalOG: any
local Blocker: any

local Requests: {
	{
		State: "Pending" | "Open" | "Closed",
		ConfirmFn: () -> (),
		CancelFn: () -> ()?,
		Window: any,
	}
} = {}

local AnimTime = UI_Info.BaseAnimTime

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function LoadNextWindow()
	local First = Requests[1]
	if not First then 
		Blocker.Visible = false
		return 
	end

	if First.State == "Pending" then
		First.State = "Open"
		First.Window:SetAttribute("Enabled", true)
		Blocker.Visible = true

	elseif First.State == "Closed" then
		First.Window:Destroy()
		table.remove(Requests, 1)
		LoadNextWindow()
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Adds a new modal window request; showing only one at a time
function ModalWindowUI.New(Message: string, ConfirmFn: () -> (), CancelFn: () -> ()?, ConfirmText: string?, CancelText: string?)
	if not Message or not ConfirmFn then return end

	-- Create
	local NewWindow = ModalOG:Clone()
	NewWindow.Name = "ModalWindow"
	NewWindow.Visible = false
	NewWindow.GroupTransparency = 1
	NewWindow.Position = OFF_POSITION
	NewWindow.Container.Message.Text = Message
	NewWindow.Container.Confirm.Frame.Label.Text = ConfirmText
	NewWindow.Container.Cancel.Frame.Label.Text = CancelText
	NewWindow.Parent = ModalOG.Parent
	
	-- Set up show / hide functionality
	local MoveTween: Tween?
	NewWindow:SetAttribute("Enabled", false)
	NewWindow:GetAttributeChangedSignal("Enabled"):Connect(function()
		if MoveTween then MoveTween:Pause(); MoveTween:Destroy(); MoveTween = nil end

		local GoalPosition, GoalTransparency = OFF_POSITION, 1
		local Direction = Enum.EasingDirection.In

		if NewWindow:GetAttribute("Enabled") then 
			GoalPosition = ON_POSITION 
			GoalTransparency = 0
			Direction = Enum.EasingDirection.Out
			NewWindow.Visible = true 
		end

		MoveTween = TweenService:Create(NewWindow, TweenInfo.new(AnimTime / 2, Enum.EasingStyle.Back, Direction), 
			{Position = GoalPosition, GroupTransparency = GoalTransparency})
		if not MoveTween then return end
		MoveTween.Completed:Connect(function() 
			if not MoveTween then return end
			if NewWindow:GetAttribute("Enabled") then return end

			-- Clean up
			Requests[1].State = "Closed"
			LoadNextWindow()
		end)
		MoveTween:Play()
	end)

	BasicInteractions.AddStandardButton(NewWindow.Container.Confirm, function()
		NewWindow:SetAttribute("Enabled", false)
		ConfirmFn()
	end)

	BasicInteractions.AddStandardButton(NewWindow.Container.Cancel, function()
		NewWindow:SetAttribute("Enabled", false)
		if not CancelFn then return end
		CancelFn()
	end)
	
	table.insert(Requests, {
		State = "Pending",
		CancelFn = CancelFn,
		ConfirmFn = ConfirmFn,
		Window = NewWindow,
	})

	LoadNextWindow()
end

function ModalWindowUI.Setup(Gui: ScreenGui)
	if not Gui then return end

	ModalOG, Blocker = Gui:FindFirstChild("ModalWindow_OG"), Gui:WaitForChild("ModalBlocker")
	if not ModalOG or not Blocker then return end

	ModalOG.Visible = false
	Blocker.Visible = false

	-- For testing only
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local Mouse = LocalPlayer:GetMouse()

	local N = 1
	Mouse.KeyDown:Connect(function(Key)
		if Key == "t" then
			N += 1
			local Store = N
			ModalWindowUI.New("Test" .. N, function() print(Store, "Confirmed!") end, function() print(Store, "Cancelled") end, "Ye", "Ne")
		end
	end)
end

return ModalWindowUI