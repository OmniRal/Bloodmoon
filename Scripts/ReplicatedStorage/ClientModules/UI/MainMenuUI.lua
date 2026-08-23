-- OmniRal

local MainMenuUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
--local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)

local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)
local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)
local ToggleSwitch = require(ReplicatedStorage.Source.ClientModules.UI.Components.ToggleSwitch)
local DragSlider = require(ReplicatedStorage.Source.ClientModules.UI.Components.DragSlider)
local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)
local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)
local Util_UI = require(ReplicatedStorage.Source.SharedModules.General.Utility.UI)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local MENU_ON_POSITION = UDim2.fromScale(0.5, 0.5)
local MENU_OFF_POSITION = UDim2.fromScale(0.5, 0.7)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Types & Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

type TabType = "Shop" | "Stats" | "Skills" | "Settings"

local DataService = Remotes.Client.DataService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local LocalPlayer = Players.LocalPlayer

local CurrentTab = "Shop"

local Menu: any?
local Base: any?
local MenuButton: any?
local Tabs: {[string]: ImageButton} = {}

local Assets = ReplicatedStorage.Assets

local AnimTime = UI_Info.BaseAnimTime

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function UpdateBase()
	if not Tabs[CurrentTab] then return end
	local Tab = Tabs[CurrentTab]
	local Color = Tab.BackgroundColor3
	local Num = Tab:GetAttribute("TabNum")

	-- Figure out the length of the black bar below the tabs
	local LeftLength = 0.25 * (Num - 1)
	local RightLength = 1 - (0.25 * Num)

	if LeftLength <= 0 then
		Base.LeftBar.Visible = false
	else
		Base.LeftBar.Visible = true
		Base.LeftBar.Size = UDim2.new(LeftLength, -3 + (Num - 2), 0, 0)
	end

	if RightLength <= 0. then
		Base.RightBar.Visible = false
	else
		Base.RightBar.Visible = true
		Base.RightBar.Size = UDim2.new(RightLength, -1 - (Num - 1), 0, 0)
	end

	-- Update the background color
	Base.Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color),
		ColorSequenceKeypoint.new(0.5, ColorPalette.JetWhite.RGB),
		ColorSequenceKeypoint.new(1, ColorPalette.JetWhite.RGB)
	}

	-- Update which window is open
	for _, Window in Base.Windows:GetChildren() do
		if not Window then continue end
		Window.Visible = Window.Name == CurrentTab
	end
end

-- Set all tabs to OFF, except a specific one; can also use a different dictionary
local function TurnOffTabs(Except: ImageButton, List: {[string]: any}?)
	local ThisList = List or Tabs

	for _, Tab in ThisList do
		if not Tab then continue end
		if Tab == Except then continue end
		Tab:SetAttribute("On", false)
	end
end

local function UpdateMenuButtonVisuals()
	if not Menu or not MenuButton then return end
	local Hover, Pressed, On, Locked = MenuButton.Button:GetAttribute("Hover"), MenuButton.Button:GetAttribute("Pressed"), MenuButton.Button:GetAttribute("On"), MenuButton.Button:GetAttribute("Locked")

	if not Locked then
		if not Hover and not Pressed then
			MenuButton.Container.Icon.Size = UDim2.fromScale(0.7, 0.7)
		elseif Hover and not Pressed then
			MenuButton.Container.Icon.Size = UDim2.fromScale(0.8, 0.8)
		elseif Pressed then
			MenuButton.Container.Icon.Size = UDim2.fromScale(0.5, 0.5)
		end
	end

	if not On then
		for x = 1, 3 do MenuButton.Container.Icon["Line" .. x].BackgroundColor3 = ColorPalette.DarkGrey.RGB end
	else
		MenuButton.Container.Icon.Line1.BackgroundColor3 = ColorPalette.OmniBlotGreen2.RGB
		MenuButton.Container.Icon.Line2.BackgroundColor3 = ColorPalette.OmniBlotBlue2.RGB
		MenuButton.Container.Icon.Line3.BackgroundColor3 = ColorPalette.OmniBlotRed2.RGB
	end

	Menu:SetAttribute("On", MenuButton.Button:GetAttribute("On"))
end

-- Hover, Pressed and On changes for the tab buttons
local function UpdateTabVisuals(Tab: ImageButton, CopyTab: ImageButton)
	if not Tab or not CopyTab then return end

	local Cover = Tab:FindFirstChild("Cover")
	if not Cover then return end

	local On, Hover, Pressed = Tab:GetAttribute("On"), Tab:GetAttribute("Hover"), Tab:GetAttribute("Pressed")
	
	Cover.Visible = false

	if On then
		CurrentTab = Tab.Name

		Tab.Size = UDim2.new(0.25, -3, 1, 0)
		Cover.Visible = false

		UpdateBase()
		TurnOffTabs(Tab)

	else
		Cover.Visible = true

		if not Hover and not Pressed then
			Tab.Size = UDim2.new(0.25, -3, 0.8, 0)
			Cover.BackgroundTransparency = 0.75
			
		elseif Hover and not Pressed then
			Tab.Size = UDim2.new(0.25, -3, 0.9, 0)
			Cover.BackgroundTransparency = 0.85

		else -- Hover and Pressed
			Tab.Size = UDim2.new(0.25, -3, 0.6, 0)
			Cover.BackgroundTransparency = 0.65
		end
	end

	CopyTab.Size = Tab.Size
end

local function UpdateSubTabVisuals(_, Tab: any, Window: any?)
	local On, Hover, Pressed = Tab.Click:GetAttribute("On"), Tab.Click:GetAttribute("Hover"), Tab.Click:GetAttribute("Pressed")
	
	Tab.Frame.BackgroundTransparency = if On then 0.25 else 0.75
	Tab.Frame.Label.TextTransparency = if On then 0.5 else 0.75
	Tab.Frame.Stroke.Transparency = if On then 0.5 else 0.75

	if not Hover and not Pressed then
		Tab.Frame.Label.Size = UDim2.fromScale(0.9, 0.9)
	elseif Hover and not Pressed then
		Tab.Frame.Label.Size = UDim2.fromScale(1, 1)
	elseif Pressed then
		Tab.Frame.Label.Size = UDim2.fromScale(0.6, 0.6)
	end

	-- Update which window is opened
	if not Window then return end
	Window.Visible = On
end

-- Hover, Pressed, Locked and On changes for the plus button that adds a skill point to the respective skill
local function UpdatePlusSkillButtonVisuals(Plus: any)
	local Hover, Pressed, Locked = Plus:GetAttribute("Hover"), Plus:GetAttribute("Pressed"), Plus:GetAttribute("Locked")
	
	if not Locked then
		Plus.Icon.ImageTransparency = 0
		Plus.Icon.ImageColor3 = ColorPalette.OmniBlotDarkRed.RGB

		if not Hover and not Pressed then
			Plus.Icon.Size = UDim2.fromScale(0.9, 0.9)

		elseif Hover and not Pressed then
			Plus.Icon.Size = UDim2.fromScale(1, 1)

		else
			Plus.Icon.Size = UDim2.fromScale(0.6, 0.6)
		end

	else
		Plus.Icon.ImageTransparency = 0.75
		Plus.Icon.Size = UDim2.fromScale(0.9, 0.9)
		Plus.Icon.ImageColor3 = ColorPalette.JetBlack.RGB
	end
end

local function TestViewportDummy()
	if not Menu then return end

	local Frame = Menu.Base.Windows.Stuff:FindFirstChild("Frame")
	if not Frame then return end

	local Dummy = ReplicatedStorage.Assets.Other.AnimDummy:Clone()
	Dummy:PivotTo(CFrame.new(0, 0, 0))
	Dummy.Parent = Frame.Viewport.WorldModel

	local NewCam = Instance.new("Camera")
	NewCam.CFrame = CFrame.new(0, 0, 10)
	NewCam.Parent = Frame.Viewport

	local NewAnim = Instance.new("Animation")
	NewAnim.AnimationId = "rbxassetid://" .. 136393663879299
	local NewTrack = Dummy.AnimationController.Animator:LoadAnimation(NewAnim)
	NewTrack.Looped = true
	NewTrack:Play()

	Frame.Viewport.CurrentCamera = NewCam
end

local function SetupBasics()
	if not Menu then return end

	Menu:SetAttribute("On", false)
	local MenuTween: any

	Menu:GetAttributeChangedSignal("On"):Connect(function()
		local GoalPosition, GoalTransparency, Direction = MENU_ON_POSITION, 0, Enum.EasingDirection.Out

		if not Menu:GetAttribute("On") then
			GoalPosition = MENU_OFF_POSITION
			GoalTransparency = 1
			Direction = Enum.EasingDirection.In
		else
			Menu.Visible = true
		end

		MenuTween = TweenService:Create(Menu, TweenInfo.new(AnimTime, Enum.EasingStyle.Back, Direction), {Position = GoalPosition, GroupTransparency = GoalTransparency})
		MenuTween.Completed:Connect(function()
			if Menu:GetAttribute("On") then return end
			Menu.Visible = false
		end)
		MenuTween:Play()
	end)
	Menu.Position = MENU_OFF_POSITION
	Menu.GroupTransparency = 1
	Menu.Visible = true

	-- Set up top tab buttons
	for _, Tab in Menu.Tabs:GetChildren() do
		if not Tab then continue end
		if not Tab:IsA("ImageButton") then continue end

		local CopyTab = Menu.BackTabs:FindFirstChild(Tab.Name)
		if not CopyTab then return end

		BasicInteractions.AddButton(Tab)
		BasicInteractions.ConnectFXInteractionsFN(Tab, UpdateTabVisuals, false, false, false, true, CopyTab)
		
		if Tab.Name == "Shop" then Tab:SetAttribute("On", true) end

		Tabs[Tab.Name] = Tab
	end
end

-- Stuff window
local function SetupStuff()
	if not Menu then return end
	local Stuff = Base.Windows.Stuff
	
	-- Wire sub tabs
	local SubTabs: {[string]: any} = {}
	for _, Button in Stuff.Tabs:GetChildren() do
		if not Button:IsA("CanvasGroup") then continue end
		
		BasicInteractions.AddButton(Button.Click, true, true)
		BasicInteractions.ConnectFXInteractionsFN(Button.Click, UpdateSubTabVisuals, nil, nil, nil, nil, Button, Stuff[Button.Name])
		Button.Click.Activated:Connect(function()
			Button.Click:SetAttribute("On", true)
			TurnOffTabs(Button.Click, SubTabs)
		end)

		SubTabs[Button.Name] = Button.Click

		-- Have this be the starting tab open
		if Button.Name == "Noobs" then Button.Click:SetAttribute("On", true) end

		UpdateSubTabVisuals(nil, Button, Stuff[Button.Name])
	end

	Stuff.Noobs.Scroller.OG.Visible = false
	Stuff.Stickers.Scroller.OG.Visible = false

	task.delay(3, function()
		MainMenuUI.UpdateStuff()
	end)
end

-- Skills window
local function SetupSkills()
	-- Wire tab buttosn
	for _, Frame in Base.Windows.Skills.List:GetChildren() do
		if not Frame:IsA("Frame") then continue end

		Frame.Right.Plus.AutoButtonColor = false
		BasicInteractions.AddButton(Frame.Right.Plus)
		BasicInteractions.ConnectFXInteractionsFN(Frame.Right.Plus, UpdatePlusSkillButtonVisuals, false, false, true, false)

		Frame.Right.Plus.Activated:Connect(function()
			if Frame.Right.Plus:GetAttribute("Locked") then return end
			local Result = DataService:RequestUpgradeSkill(Frame.Name)
			if Result == 1 then
				print("Success!")
			else
				print(Result)
			end
		end)
	end
end

-- Settings window
local function SetupSettings()
	if not Menu then return end
	local Settings = Base.Windows.Settings

	local TimerFormatSwitch = Settings.Box.Scroller.TimerFormat.Switch

	local MusicVolumeSlider = Settings.Box.Scroller.MusicVolume.Slider
	local VoiceoversVolumeSlider = Settings.Box.Scroller.VoiceoversVolume.Slider
	local SoundFXVolumeSlider = Settings.Box.Scroller.SoundFXVolume.Slider

	ToggleSwitch.AddSwitch(TimerFormatSwitch, function() 
		local Success, Result = DataService:RequestChangeSetting("DisplayMinutes", not TimerFormatSwitch.Button:GetAttribute("On"))
		if not Success then return end
		PlayerInfo.Data.Settings.DisplayMinutes = Result
		TimerFormatSwitch.Button:SetAttribute("On", not TimerFormatSwitch.Button:GetAttribute("On"))
	end, true)

	DragSlider.AddSlider(MusicVolumeSlider, function() 
		DataService:RequestChangeSetting("MusicVolume", MusicVolumeSlider:GetAttribute("Val"))
		SoundService.Music.Volume = MusicVolumeSlider:GetAttribute("Val")
	end, NumberRange.new(0, 1), 10, 1)

	DragSlider.AddSlider(VoiceoversVolumeSlider, function() 
		DataService:RequestChangeSetting("VoiceoversVolume", VoiceoversVolumeSlider:GetAttribute("Val"))
		SoundService.Voiceovers.Volume = VoiceoversVolumeSlider:GetAttribute("Val")
	end, NumberRange.new(0, 1), 10, 1)

	DragSlider.AddSlider(SoundFXVolumeSlider, function() 
		DataService:RequestChangeSetting("SoundFXVolume", SoundFXVolumeSlider:GetAttribute("Val"))
		SoundService.SoundFX.Volume = SoundFXVolumeSlider:GetAttribute("Val")
	end, NumberRange.new(0, 1), 10, 1)

	task.delay(3, function()
		while true do
			task.wait(0.1)
			if not PlayerInfo then continue end
			if not PlayerInfo.Data then continue end
			if not PlayerInfo.Data.Settings then continue end
			break
		end

		TimerFormatSwitch.Button:SetAttribute("On", PlayerInfo.Data.Settings.DisplayMinutes)
		MusicVolumeSlider:SetAttribute("ForceVal", PlayerInfo.Data.Settings.MusicVolume)
		VoiceoversVolumeSlider:SetAttribute("ForceVal", PlayerInfo.Data.Settings.VoiceoversVolume)
		SoundFXVolumeSlider:SetAttribute("ForceVal", PlayerInfo.Data.Settings.SoundFXVolume)

		warn("Music: ", PlayerInfo.Data.Settings.MusicVolume)
		warn("Voiceover: ", PlayerInfo.Data.Settings.VoiceoversVolume)
		warn("Sound FX: ", PlayerInfo.Data.Settings.SoundFXVolume)



		SoundService.Music.Volume = PlayerInfo.Data.Settings.MusicVolume
		SoundService.Voiceovers.Volume = PlayerInfo.Data.Settings.VoiceoversVolume
		SoundService.SoundFX.Volume = PlayerInfo.Data.Settings.SoundFXVolume


	end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MainMenuUI.UpdateStuff()
end

function MainMenuUI.UpdateSkills()
end

function MainMenuUI.Setup(Gui: ScreenGui)
	if not Gui then return end

	Menu = Gui:FindFirstChild("Menu")
	if not Menu then return end

	Base, MenuButton = Menu:FindFirstChild("Base"), Gui:FindFirstChild("MenuButton")
	if not Base or not MenuButton then return end

	-- Set up menu button
	BasicInteractions.AddButton(MenuButton.Button, true)
	BasicInteractions.ConnectFXInteractionsFN(MenuButton.Button, UpdateMenuButtonVisuals)
	UpdateMenuButtonVisuals()

	task.wait(1)

	SetupBasics()
	SetupSkills()
	SetupStuff()
	SetupSettings()

	TestViewportDummy()
end

return MainMenuUI