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

local MAX_WEAVE_PATH_STEPS = 100
local DEFAULT_ARRIVE_RANGE = 16
local DEFAULT_WEAVE_WIDTH = 6

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local LevelSizes: {number} = {220, 340, 420, 540}

local MapPoints: {CFrame} = {} -- Where map fragments will be placed
local PathPoints: {CFrame} = {}

local Assets = ServerStorage.Assets
local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Snap a number to the cell grid
-- @Offset = If TRUE, reduces the number by half of the cell size
local function SnapToGrid(Num: number, Offset: boolean?): number
	return math.round(Num / CELL_SIZE) * CELL_SIZE + (if Offset then -2 else 0)
end

local function ArePointsClose(A: Vector3, B: Vector3, Range: number): boolean
	return (A - B).Magnitude <= Range
end

local function IsPointCloseToAnyInList(ThisPoint: Vector3, ThisList: {CFrame | Vector3}, Range: number): boolean
	if not ThisPoint or not ThisList then return false end

	for _, Point in ThisList do
		if typeof(Point) == "CFrame" then
			if not ArePointsClose(ThisPoint, Point.Position, Range) then continue end
			return true

		elseif typeof(Point) == "Vector3" then
			if not ArePointsClose(ThisPoint, Point, Range) then continue end
			return true
		end
	end

	return false
end

--  Weaves a curvy path between two points
-- @ArriveRange = How close to the goal counts as "arriving"
-- @Width = How wide the path should; how many cells it allocates per step
local function CarveWeavingPathFrom(Start: Vector3, Goal: Vector3, ArriveRange: number?, Width: number?)
	local CurrentStep = CFrame.new(Vector3.new(Start.X, 0, Start.Z), Vector3.new(Goal.X, 0, Goal.Z))
	local Angles = {-45, -30, 30, 45}
	
	for _ = 1, MAX_WEAVE_PATH_STEPS do
		-- Twist path left or right
		CurrentStep *= CFrame.Angles(0, math.rad(Angles[RNG:NextInteger(1, 4)]), 0)

		-- Step forward
		CurrentStep *= CFrame.new(0, 0, -CELL_SIZE * 2)
		--[[local Dot = Utility.CreateDot(CurrentStep, Vector3.new(3, 3, 3), Enum.PartType.Block, Color3.fromRGB(0, 255, 0))
		Dot.Material = Enum.Material.SmoothPlastic
		Dot.FrontSurface = "Hinge"]]

		CurrentStep = CFrame.new(SnapToGrid(CurrentStep.Position.X), 0, SnapToGrid(CurrentStep.Position.Z))

		-- Add path cell if it's not already added
		if not table.find(PathPoints, CurrentStep) then
			table.insert(PathPoints, CurrentStep)
		end

		if ArePointsClose(CurrentStep.Position, Goal, ArriveRange or DEFAULT_ARRIVE_RANGE) then break end

		-- Reset current step
		CurrentStep = CFrame.new(Vector3.new(CurrentStep.Position.X, 0, CurrentStep.Position.Z), Vector3.new(Goal.X, 0, Goal.Z))
	end
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

	local MapPlaceCalc = ((LevelWidth / 2) - 20)

	for _ = 1, 4 do
		-- Try to make sure two map points are not too close to each other
		local NewPoint: CFrame
		for _ = 1, 100 do
			NewPoint = CFrame.new(
				SnapToGrid(RNG:NextInteger(-MapPlaceCalc, MapPlaceCalc)),
				0,
				SnapToGrid(RNG:NextInteger(-MapPlaceCalc, MapPlaceCalc))
			)

			if #MapPoints <= 0 then break end
			if IsPointCloseToAnyInList(NewPoint.Position, MapPoints, 40) then continue end

			break
		end
		table.insert(MapPoints, NewPoint)
		Utility.CreateDot(NewPoint, Vector3.new(4, 4, 4), Enum.PartType.Ball, Color3.fromRGB(255, 0, 0))
	end

	local PathCombosMade: {{A: number, B: number}} = {}
	for _ = 1, RNG:NextInteger(1, 4) do
		
	end
	CarveWeavingPathFrom(MapPoints[1].Position, MapPoints[2].Position)
	CarveWeavingPathFrom(MapPoints[2].Position, MapPoints[3].Position)
	CarveWeavingPathFrom(MapPoints[3].Position, MapPoints[4].Position)
	CarveWeavingPathFrom(MapPoints[4].Position, MapPoints[1].Position)

	
	-- Make the trees
	local TreeFolder = New.Instance("Folder", "Trees", LevelFolder)
	local CurrentCF = CFrame.new(-LevelWidth / 2, 0.5, -LevelWidth / 2)
	for x = 1, TotalCells do
		for z = 1, TotalCells do
			local PlaceHere = CurrentCF
			local Noise = math.noise(PlaceHere.Position.X / NOISE_SCALE, PlaceHere.Position.Z / NOISE_SCALE)
			CurrentCF *= CFrame.new(0, 0, CELL_SIZE)
			if Noise > 0.12 then continue end

			-- Check to make sure it's not near any map fragments, path points
			if IsPointCloseToAnyInList(CurrentCF.Position, MapPoints, 8) then continue end
			if IsPointCloseToAnyInList(CurrentCF.Position, PathPoints, DEFAULT_WEAVE_WIDTH) then continue end

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