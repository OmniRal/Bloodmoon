-- OmniRal

local BounceOriginal = {}

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

function BounceOriginal.Setup(Original: any, _, NicerModel: any)
    
    local PointA = Original.CFrame * CFrame.new(0, Original.Size.Y / 2, Original.Size.Z / 2)
    local PointB = Original.CFrame * CFrame.new(0, -Original.Size.Y / 2, -Original.Size.Z / 2)
    local PlaceHere = CFrame.new(PointA.Position, PointB.Position)
    
    NicerModel:PivotTo(PlaceHere)
    
    local RotVal = Instance.new("NumberValue")
    RotVal.Name = "Rot"
    RotVal.Value = 0
    RotVal.Parent = NicerModel
    RotVal.Changed:Connect(function() NicerModel:PivotTo(PlaceHere * CFrame.Angles(math.rad(RotVal.Value), 0, 0)) end)

    local Distance = (PointA.Position - PointB.Position).Magnitude

    NicerModel.Rod.Size = Vector3.new(Original.Size.X, 0.5, 0.5)
    NicerModel.Main.Size = Vector3.new(Original.Size.X, 0.25, Distance)
    NicerModel.Main.CFrame = NicerModel.Rod.CFrame * CFrame.new(0, 0, -Distance / 2)
    NicerModel.Main.Color = Original.Color
    NicerModel.Edge.Size = Vector3.new(Original.Size.X, 0.5, 0.25)
    NicerModel.Edge.CFrame = NicerModel.Main.CFrame * CFrame.new(0, -0.25, -Distance / 2 + 0.125)
    NicerModel.Edge.Color = Original.Color

    Original.Texture:Clone().Parent = NicerModel.Main
    local MainTexture = Original.Texture:Clone()
    MainTexture.Face = Enum.NormalId.Top
    MainTexture.Parent = NicerModel.Main
    local EdgeTexture = Original.Texture:Clone()
    EdgeTexture.Face = Enum.NormalId.Front
    EdgeTexture.Parent = NicerModel.Edge

    local PlayingAnimation = false
	Original:GetAttributeChangedSignal("Launched"):Connect(function()
		if not Original:GetAttribute("Launched") then return end
		if PlayingAnimation then return end

        PlayingAnimation = true
        local FlapOut = TweenService:Create(RotVal, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Value = 45})
        local FlapIn = TweenService:Create(RotVal, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Value = 0})

        FlapOut.Completed:Connect(function() FlapIn:Play() end)
        FlapIn.Completed:Connect(function() PlayingAnimation = false end)

        FlapOut:Play()
	end)

    Original.Transparency = 1
    Original.Texture:Destroy()
end

return BounceOriginal