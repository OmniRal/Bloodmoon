-- OmniRal

local LevelController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

local function PlaceTrees(LevelName: string, TreeFolder: Folder)
	if not TreeFolder then return end

	local TreeAssets = Assets.Level.Trees[LevelName]:GetChildren()
	local TotalPlaced = 0

	for _, BaseTree in TreeFolder:GetChildren() do
		if not BaseTree then continue end
		BaseTree.Transparency = 1
		local NewTree = TreeAssets[RNG:NextInteger(1, #TreeAssets)]:Clone()
		NewTree.Visual:PivotTo(
			BaseTree.CFrame *
			CFrame.new(RNG:NextNumber(-0.5, 0.5), 0, RNG:NextNumber(-0.5, 0.5)) *
			CFrame.Angles(0, math.rad(RNG:NextInteger(-15, 15)), 0)
		)
		NewTree.Parent = TreeFolder

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