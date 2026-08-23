-- OmniRal

local BounceBumper = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AssetService = game:GetService("AssetService")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local FLAT_MESH = true
local GRID_SIZE = 8

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Build the actual editable mesh that will stretch
local function BuildStretchyMaterial(Center: BasePart): (BasePart?, {}?)
	if not FLAT_MESH then
		local GridSize = GRID_SIZE
		local Width = Center.Size.X
		local Height = Center.Size.Y

		local Mesh = AssetService:CreateEditableMesh()

		local Vertices: { 
			{Id: number, Rest: Vector3} 
		} = {}
		local Grid: {
			[number]: {number}
		} = {}

		for Row = 0, GridSize do
			Grid[Row] = {}
			local Y = (Row / GridSize - 0.5) * Height

			for Col = 0, GridSize do
				local X = (Col / GridSize - 0.5) * Width
				local RestPosition = Vector3.new(X, Y, 0)
				local VertexId = Mesh:AddVertex(RestPosition)
				Grid[Row][Col] = VertexId

				table.insert(Vertices, { Id = VertexId, Rest = RestPosition })
			end
		end

		for Row = 0, GridSize - 1 do
			for Col = 0, GridSize - 1 do
				local TopLeft = Grid[Row][Col]
				local TopRight = Grid[Row][Col + 1]
				local BottomLeft = Grid[Row + 1][Col]
				local BottomRight = Grid[Row + 1][Col + 1]

				Mesh:AddTriangle(TopLeft, BottomLeft, TopRight)
				Mesh:AddTriangle(TopRight, BottomLeft, BottomRight)
			end
		end

		local MeshPart = AssetService:CreateMeshPartAsync(Content.fromObject(Mesh), {
			CollisionFidelity = Enum.CollisionFidelity.Box,
		})
		MeshPart.Name = "StretchyMaterial"
		MeshPart.Anchored = true
		MeshPart.CanCollide = false
		MeshPart.CanQuery = false
		MeshPart.CanTouch = false
		MeshPart.CastShadow = false
		MeshPart.DoubleSided = true
		MeshPart.Material = Enum.Material.SmoothPlastic
		MeshPart.Color = Center.Color
		MeshPart.CFrame = Center.CFrame
		MeshPart.Parent = Center.Parent

		local Decal = Instance.new("Decal")
		Decal.Texture = "rbxassetid://98851568916910"
		Decal.Transparency = 0.75
		Decal.Face = Enum.NormalId.Front
		Decal.Parent = MeshPart

		return Mesh, Vertices
	
	else
		Center.Transparency = 0

		local Decal = Instance.new("Decal")
		Decal.Texture = "rbxassetid://98851568916910"
		Decal.Transparency = 0.75
		Decal.Face = Enum.NormalId.Front
		Decal.Parent = Center

		return
	end
end

-- Returns a stretch function that morphs the mesh to look like a trampoline
local function CreateStretchController(Mesh: EditableMesh, Vertices: {any}, Center: BasePart)
	local CenterPoint = Vector2.new(0, 0) 
	local MaxDepth = math.min(Center.Size.X, Center.Size.Y) * 1
	local ImpactRadius = math.max(Center.Size.X, Center.Size.Y) * 0.6


	local Falloffs = {}
	for _, VertexInfo in Vertices do
		local Flat = Vector2.new(VertexInfo.Rest.X, VertexInfo.Rest.Y)
		local Distance = (Flat - CenterPoint).Magnitude
		local Alpha = math.clamp(1 - (Distance / ImpactRadius), 0, 1)

		Falloffs[VertexInfo.Id] = Alpha * Alpha * (3 - 2 * Alpha)
	end

	local function SetDepth(Factor: number)
		for _, VertexInfo in Vertices do
			local Offset = Factor * MaxDepth * Falloffs[VertexInfo.Id]
			Mesh:SetPosition(VertexInfo.Id, VertexInfo.Rest + Vector3.new(0, 0, Offset))
		end
	end

	return SetDepth
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function BounceBumper.Setup(Original: any, PlaceHere: CFrame, NicerModel: any)
	Original.Transparency = 1
	
	-- Set up the frames correctly
	NicerModel.TopFrame.CFrame = PlaceHere * CFrame.new(0, Original.Size.Y / 2 - 0.25, 0)
	NicerModel.TopFrame.Size = Vector3.new(Original.Size.X, 0.5, 1)
	
	NicerModel.BottomFrame.CFrame = PlaceHere * CFrame.new(0, -Original.Size.Y / 2 + 0.25, 0)
	NicerModel.BottomFrame.Size = Vector3.new(Original.Size.X, 0.5, 1)
	
	NicerModel.LeftFrame.CFrame = PlaceHere * CFrame.new(-Original.Size.X / 2 + 0.25, 0, 0)
	NicerModel.LeftFrame.Size = Vector3.new(0.5, Original.Size.Y - 1, 1)
	
	NicerModel.RightFrame.CFrame = PlaceHere * CFrame.new(Original.Size.X / 2 - 0.25, 0, 0)
	NicerModel.RightFrame.Size = Vector3.new(0.5, Original.Size.Y - 1, 1)
	
	NicerModel.Center.Size = Vector3.new(Original.Size.X - 1, Original.Size.Y - 1, 0.1)
	NicerModel.Center.Transparency = 1 -- Hiding it for now
	
	local Mesh, Vertices = BuildStretchyMaterial(NicerModel.Center)
	local Depth

	if (not FLAT_MESH) and (Mesh and Vertices) then
		local SetDepth = CreateStretchController(Mesh, Vertices, NicerModel.Center)

		Depth = Instance.new("NumberValue")
		Depth.Name = "Depth"
		Depth.Value = 0
		Depth.Parent = NicerModel
		Depth.Changed:Connect(function() SetDepth(Depth.Value) end) -- Update the stretch based on this value
	end

	local PlayingAnimation = false

	Original:GetAttributeChangedSignal("Launched"):Connect(function()
		if not Original:GetAttribute("Launched") then return end

		if FLAT_MESH then return end
		if PlayingAnimation then return end
		local StretchIn = TweenService:Create(Depth, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Value = 0.3})
		local StretchOut = TweenService:Create(Depth, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Value = -0.6})
		local Flatten = TweenService:Create(Depth, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Value = 0})

		StretchIn.Completed:Connect(function() StretchOut:Play() end)
		StretchOut.Completed:Connect(function() Flatten:Play() end)
		Flatten.Completed:Connect(function() PlayingAnimation = false end)

		StretchIn:Play()
	end)
end

return BounceBumper