-- OmniRal

local MainUIController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
--local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
--local TweenService = game:GetService("TweenService")
--local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

local LevelXPCurve = require(ReplicatedStorage.Source.SharedModules.General.Utility.LevelXPCurve)

--local CustomEnum = require(ReplicatedStorage.Source.SharedModules.Info.CustomEnum)
local DeviceController = require(StarterPlayer.StarterPlayerScripts.Source.General.DeviceController)
local PlayerInfo = require(StarterPlayer.StarterPlayerScripts.Source.Other.PlayerInfo)

--local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
local MainMenuUI = require(ReplicatedStorage.Source.ClientModules.UI.MainMenuUI)
local ErrorMessageUI = require(ReplicatedStorage.Source.ClientModules.UI.ErrorMessageUI)
local ModalWindowUI = require(ReplicatedStorage.Source.ClientModules.UI.ModalWindowUI)

--local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)
--local ToggleSwitch = require(ReplicatedStorage.Source.ClientModules.UI.Components.ToggleSwitch)
--local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ADD_XP_PAUSE = 1 -- How many seconds to pause adding more XP to the bar after leveling up

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local VisualService = Remotes.VisualService
local DataService = Remotes.Client.DataService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MainUIController.Menu = "None"
MainUIController.Modules = {
	["ErrorMessageUI"] = ErrorMessageUI,
}

local LocalPlayer = Players.LocalPlayer

local Gui: any

local AddXPPauseUntil = 0
local CachedTweens: {[any]: Tween} = {}

--local AnimTime = UI_Info.BaseAnimTime

local Assets = ReplicatedStorage.Assets

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CreateNewGui()
    Gui = Assets.UIs.MainGui:Clone()
    Gui.Parent = LocalPlayer.PlayerGui

	-- Destroy copies
    task.spawn(function()
        for _ = 1, 20 do
            task.wait(0.2)
            for _, OldGui in LocalPlayer.PlayerGui:GetChildren() do
                if not OldGui then continue end
                if OldGui.Name == "MainGui" and OldGui ~= Gui then
                    OldGui:Destroy()
                end
            end
        end
    end)
end


local function SetupGui()
	MainMenuUI.Setup(Gui)
	ErrorMessageUI.Setup(Gui)
	ModalWindowUI.Setup(Gui)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MainUIController.RunAbilityCooldown(ThisAbility: "Push" | "Dodge", Time: number)
	if not Gui then return end
	if not Gui:FindFirstChild("AbilityInfo") then return end
	
	local Frame = Gui.AbilityInfo:FindFirstChild(ThisAbility)
	if not Frame then return end

	if CachedTweens[Frame] then
		CachedTweens[Frame]:Pause()
		CachedTweens[Frame]:Destroy()
		CachedTweens[Frame] = nil
	end

	Frame.Fill.Size = UDim2.fromScale(1, 1)
	CachedTweens[Frame] = TweenService:Create(Frame.Fill, TweenInfo.new(Time, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(1, 0)})
	CachedTweens[Frame].Completed:Connect(function() 
		Frame.Icon.ImageTransparency = 0.25
	end)

	CachedTweens[Frame]:Play()
	Frame.Icon.ImageTransparency = 0.75
end

-- Update all data dependent elements of the UI
function MainUIController.UpdateAllUI()
	MainMenuUI.UpdateSkills()
end

function MainUIController.SetCharacter()
    if not LocalPlayer.Character then return end
end

function MainUIController.RunHeartbeat(DeltaTime: number)
	if not DeltaTime then return end

end

function MainUIController:Init()
    CreateNewGui()
end

function MainUIController:Deferred()
    SetupGui()

    DeviceController.CurrentDevice:Connect(function()
        print("Main UI Controller Device ", DeviceController.CurrentDevice:Get())
    end)

	while true do
		task.wait()
		if not Remotes.Client.DataService or not Remotes.Client.PushService then continue end
		DataService = Remotes.Client.DataService
		break
	end

	DataService.FullDataUpdate:Connect(function()
		task.defer(function() MainUIController.UpdateAllUI() end)
	end)

	DataService.MultiDataUpdate:Connect(function(UpdateList: {[string]: any})
		task.defer(function() 
			for Entry, Value in UpdateList do
			end
		end)
	end)

	DataService.SingleDataUpdate:Connect(function(Index, Value: any)
        task.defer(function()
            --local PData = PlayerInfo.Data

            if typeof(Index) == "string" then

            elseif typeof(Index) == "table" then
            end
        end)
    end)

    DataService.GiveAddXP:Connect(function(ThisMuch: number)
        PlayerInfo.AddXP += ThisMuch
    end)

    RunService.Heartbeat:Connect(function(DeltaTime: number)
        MainUIController.RunHeartbeat(DeltaTime)
    end)
end

return MainUIController