-- OmniRal

local LevelService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local New = require(ReplicatedStorage.Source.Pronghorn.New)
local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)
local SharedGlobalValues = require(ReplicatedStorage.Source.SharedModules.Top.SharedGlobalValues)

local Utility = require(ReplicatedStorage.Source.SharedModules.General.Utility)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SPAWN_TEST_Level = true
local SHOW_TREE_BASES = true
local NOISE_SCALE = 10
local CELL_SIZE = 4

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LevelSizes: {number} = {220, 340, 420, 540}

local Assets = ServerStorage.Assets
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function ArePointsClose(A: Vector3, B: Vector3, Range: number)
	return (A - B).Magnitude <= Range
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function LevelService.Build(LevelName: string, OverrideSize: number?)
	local LevelFolder = New.Instance("Folder", "Level", Workspace)
	LevelFolder:SetAttribute("LevelName", LevelName)
	LevelFolder:SetAttribute("BuildComplete", false)

	local LevelWidth = OverrideSize or LevelSizes[math.clamp(#Players:GetChildren(), SharedGlobalValues.MinPlayers, SharedGlobalValues.MaxPlayers)]
	local TotalCells = LevelWidth / CELL_SIZE

	local MapPoints: {CFrame} = {} -- Where map fragments will be placed
	local MapPlaceCalc = (TotalCells - 4) * (CELL_SIZE / 2)

	for _ = 1, 4 do
		-- Try to make sure two map points are not too close to each other
		local NewPoint: CFrame
		for _ = 1, 100 do
			NewPoint = CFrame.new(
				RNG:NextInteger(-MapPlaceCalc, MapPlaceCalc),
				0,
				RNG:NextInteger(-MapPlaceCalc, MapPlaceCalc)
			)

			if #MapPoints <= 0 then break end

			local IsClose = false
			for _, OtherPoint in MapPoints do
				if not ArePointsClose(NewPoint.Position, OtherPoint.Position, 40) then continue end
				IsClose = true
				break
			end

			if IsClose then continue end
			break
		end
		table.insert(MapPoints, NewPoint)
		Utility.CreateDot(NewPoint, Vector3.new(4, 4, 4), Enum.PartType.Ball, Color3.fromRGB(255, 0, 0))
	end
	
	-- Make the trees
	local TreeFolder = New.Instance("Folder", "Trees", LevelFolder)
	local CurrentCF = CFrame.new(-LevelWidth / 2, 0.5, -LevelWidth / 2)
	for x = 1, TotalCells do
		for z = 1, TotalCells do
			local PlaceHere = CurrentCF
			local Noise = math.noise(PlaceHere.Position.X / NOISE_SCALE, PlaceHere.Position.Z / NOISE_SCALE)
			CurrentCF *= CFrame.new(0, 0, CELL_SIZE)
			if Noise > 0.12 then continue end

			-- Check to make sure it's not near any map fragments
			local IsClose = false
			for _, Point in MapPoints do
				if not Point then continue end
				if not ArePointsClose(PlaceHere.Position, Point.Position, 8) then continue end
				IsClose = true
				break
			end

			if IsClose then continue end

			local NewTreeBase = Assets.Level.BaseTree:Clone()
			NewTreeBase.CFrame = PlaceHere
			if SHOW_TREE_BASES then NewTreeBase.Transparency = 0 end
			NewTreeBase.Parent = TreeFolder
			
		end

		task.wait()
		CurrentCF *= CFrame.new(CELL_SIZE, 0, -LevelWidth)
	end

	LevelFolder:SetAttribute("BuildComplete", true)
	Remotes.Server.LevelService.LevelBuilt:FireAll()
end

function LevelService:Deferred()
	task.delay(3, function()
		if not SPAWN_TEST_Level then return end
		LevelService.Build("Forest")
	end)

	Remotes.Server:CreateToClient("LevelBuilt", {})
end

return LevelService