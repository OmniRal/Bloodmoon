-- OmniRal

local BounceDoor = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function BounceDoor.Setup(Original: any)
	local PlayingAnimation = false

    local DoorModel = Instance.new("Model")
    DoorModel.Name = "DoorModel"
    DoorModel.Parent = Original.Parent

    Original.Parent = DoorModel

    local Side = if Original.Side.Position.X < 0 then -1 else 1
    local Hinge = Instance.new("Part")
    Hinge.Name = "Hinge"
    Hinge.Anchored = true
    Hinge.CanCollide = false
    Hinge.CanQuery = false
    Hinge.CanTouch = false
    Hinge.Transparency = 1
    Hinge.Size = Vector3.new(1, 1, 1)
    Hinge.CFrame = Original.CFrame * CFrame.new(Original.Size.X / 2 * Side, 0, 0)
    Hinge.Parent = DoorModel

    DoorModel.PrimaryPart = Hinge

    local OriginalCF = DoorModel:GetPivot()

    local RotVal = Instance.new("NumberValue")
    RotVal.Name = "Rot"
    RotVal.Value = 0
    RotVal.Parent = Hinge
    RotVal.Changed:Connect(function() DoorModel:PivotTo(OriginalCF * CFrame.Angles(0, math.rad(RotVal.Value), 0)) end)

	Original:GetAttributeChangedSignal("Launched"):Connect(function()
		if not Original:GetAttribute("Launched") then return end
		if PlayingAnimation then return end

        PlayingAnimation = true
        local FlapOut = TweenService:Create(RotVal, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Value = 135 * -Side})
        local FlapIn = TweenService:Create(RotVal, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Value = 0})

        FlapOut.Completed:Connect(function() FlapIn:Play() end)
        FlapIn.Completed:Connect(function() PlayingAnimation = false end)

        FlapOut:Play()
	end)

    Original.FrontSurface = "Smooth"
end

return BounceDoor