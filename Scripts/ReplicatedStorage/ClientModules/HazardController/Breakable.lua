-- OmniRal

local Breakable = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CLEAN_DEBRIS_TIME = NumberRange.new(2, 4)

local GLASS_CORNERS = {
	Vector3.new(-1, 1),
	Vector3.new(1, 1),
	Vector3.new(-1, -1),
	Vector3.new(1, -1)
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RNG = Random.new()

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Breakable.Setup(Original: BasePart, _, NicerModel: Model)
	local Style = Original:GetAttribute("Style")

	Original.Transparency = 1

	local DecorParts: {BasePart} = {}

	if Style == 0 then
		-- Glass
		for x = 1, 4 do
			local Corner = GLASS_CORNERS[x]

			local Glass = Instance.new("Part")
			Glass.Name = "Glass"
			Glass.Anchored = true
			Glass.CanCollide = true
			Glass.CanQuery = false
			Glass.CanTouch = false
			Glass.Material = Enum.Material.Glass
			Glass.Transparency = 0.5
			Glass.Color = Color3.fromRGB(136, 203, 213)
			Glass.Size = Vector3.new(Original.Size.X / 2, Original.Size.Y / 2, 0.1)
			Glass.CFrame = Original.CFrame * CFrame.new(Corner.X * (Original.Size.X / 4), Corner.Y * (Original.Size.Y / 4), 0)
			Glass.CollisionGroup = "Debris"
			Glass:SetAttribute("OriginalTransparency", Glass.Transparency)
			Glass.Parent = NicerModel
			table.insert(DecorParts, Glass)
		end

	elseif Style == 1 then
		-- Railing
		local BaseRail = Instance.new("Part")
		BaseRail.Name = "Rail"
		BaseRail.Anchored = true
		BaseRail.CanCollide = false
		BaseRail.CanQuery = false
		BaseRail.CanTouch = false
		BaseRail.Material = Enum.Material.SmoothPlastic
		BaseRail.Color = Color3.fromRGB(35, 52, 73)
		BaseRail.CollisionGroup = "Debris"

		local Top = BaseRail:Clone()
		Top.Size = Vector3.new(Original.Size.X, 0.5, 1)
		Top.CFrame = Original.CFrame * CFrame.new(0, Original.Size.Y / 2 - 0.25, 0)
		Top.Parent = NicerModel
		table.insert(DecorParts, Top)

		for x = -1, 1 do
			if x == 0 and Original.Size.X < 8 then continue end -- Only make a peg in the middle if the railing stretches to 8 and above
			local Peg = BaseRail:Clone()
			Peg.Size = Vector3.new(1, Original.Size.Y - 0.5, 0.5)
			Peg.CFrame = Original.CFrame * CFrame.new( ((Original.Size.X / 2) - 0.5) * x , -0.25, 0)
			Peg.Parent = NicerModel

			table.insert(DecorParts, Peg)
		end
	end

	Original:GetAttributeChangedSignal("Broken"):Connect(function()
		
		if Original:GetAttribute("Broken") then
			local Direction = Original:GetAttribute("Direction")
			for _, Part in DecorParts do
				if not Part then continue end

				local Copy = Part:Clone()
				Copy.Anchored = false
				Copy.CanCollide = true
				Copy.AssemblyLinearVelocity = Direction + Vector3.new(RNG:NextNumber(-3, 3), RNG:NextNumber(-3, 3), RNG:NextNumber(-3, 3))
				Copy.AssemblyAngularVelocity = Vector3.new(
					RNG:NextInteger(-Direction.X / 2, Direction.X / 2), 
					RNG:NextInteger(-Direction.Y / 2, Direction.Y / 2),
					RNG:NextInteger(-Direction.Z / 2, Direction.Z / 2)
				)
				Copy.Parent = Workspace.Debris
				Debris:AddItem(Copy, RNG:NextNumber(CLEAN_DEBRIS_TIME.Min, CLEAN_DEBRIS_TIME.Max))

				Part.Transparency = 1
			end

		else
			for _, Part in DecorParts do
				if not Part then continue end
				Part.Transparency = Part:GetAttribute("OriginalTransparency") or 0
			end
		end
	end)
end

return Breakable