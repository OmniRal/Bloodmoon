-- OmniRal

local LevelController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TREE_SHAKE_COOLDOWN = 1.1

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LevelService = Remotes.Client.LevelService

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Assets = ReplicatedStorage.Assets
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function ForestTreeShake(LeavesData: {[BasePart]: CFrame})
	local ShakeAngles = {15, 30, 45}

	for Leaves, OriginalCF in LeavesData do
		if not Leaves or not OriginalCF then continue end

		local StartTime = RNG:NextNumber(0.2, 0.35)

		local Tween_1 = TweenService:Create(Leaves, TweenInfo.new(StartTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			CFrame = OriginalCF * CFrame.Angles(0, math.rad(ShakeAngles[RNG:NextInteger(1, 3)] * (-1 + (RNG:NextInteger(0, 1) * 2))), 0)})

		local Tween_2 = TweenService:Create(Leaves, TweenInfo.new(1 - StartTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = OriginalCF})

		Tween_1.Completed:Connect(function() if not Tween_2 then return end; Tween_2:Play() end)
		Tween_1:Play()
	end
end

local function PlaceTrees(LevelName: string, TreeFolder: Folder)
	if not TreeFolder then return end

	local TreeAssets = Assets.Level.Trees[LevelName]:GetChildren()
	local TotalPlaced = 0

	for _, BaseTree in TreeFolder:GetChildren() do
		if not BaseTree then continue end
		BaseTree.Transparency = 1

		-- Add the visual
		local LeavesData: {[BasePart]: CFrame} = {}
		local NewTree = TreeAssets[RNG:NextInteger(1, #TreeAssets)]:Clone()
		NewTree.Visual:PivotTo(
			BaseTree.CFrame *
			CFrame.new(RNG:NextNumber(-0.5, 0.5), 0, RNG:NextNumber(-0.5, 0.5)) *
			CFrame.Angles(0, math.rad(RNG:NextInteger(-15, 15)), 0)
		)
		NewTree.Parent = TreeFolder

		-- Store the leaves and their original CFrame
		for _, Leaves in NewTree.Visual:GetChildren() do
			if not Leaves then continue end
			LeavesData[Leaves] = Leaves.CFrame
		end

		-- Create the touch connection w/ animation
		local Debounce = false
		BaseTree.CanTouch = true
		BaseTree.Touched:Connect(function()
			if Debounce then return end
			Debounce = true
			BaseTree.CanTouch = false

			-- Shake tweens for the leaves
			ForestTreeShake(LeavesData)

			task.wait(TREE_SHAKE_COOLDOWN)
			BaseTree.CanTouch = true
			Debounce = false
		end)

		TotalPlaced += 1
		if TotalPlaced % 10 == 0 then task.wait() end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function LevelController.Build(): boolean
	task.wait(0.5)
	local LevelFolder = Workspace:FindFirstChild("Level")
	if not LevelFolder then return false end

	-- Wait for build to complete
	while true do
		task.wait(0.25)
		if not LevelFolder:GetAttribute("BuildComplete") then continue end
		break
	end

	local LevelName = LevelFolder:GetAttribute("LevelName")

	local TreeFolder = LevelFolder:FindFirstChild("Trees")
	if not TreeFolder then return false end

	PlaceTrees(LevelName, TreeFolder)

	return true
end

function LevelController:Deferred()
	Utility.CheckRemotesLoaded({"LevelService"})
	LevelService = Remotes.Client.LevelService

	LevelService.LevelBuilt:Connect(function()
		LevelController.Build()
	end)
end

return LevelController