-- OmniRal

local BounceAwning = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Debris = game:GetService("Debris")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CLEAN_TIME = 0.05
local COOLDOWN = 0.5

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

function BounceAwning.Setup(Awning: BasePart)
	local Power = Awning:GetAttribute("Power") :: NumberRange
    local Debounce = false
    
    local PointA = Awning.CFrame * CFrame.new(0, Awning.Size.Y / 2, Awning.Size.Z / 2)
    local PointB = Awning.CFrame * CFrame.new(0, -Awning.Size.Y / 2, -Awning.Size.Z / 2)
    local Normal = CFrame.new((PointA.Position + PointB.Position) / 2, PointB.Position).UpVector

    Awning:SetAttribute("Launched", false)

    Awning.Touched:Connect(function(Hit: BasePart)
        if Debounce then return end
        if not Hit then return end
        if not Hit.Parent then return end
        local Human, Root = Hit.Parent:FindFirstChild("Humanoid") :: Humanoid, Hit.Parent:FindFirstChild("HumanoidRootPart") :: BasePart
        if not Human or not Root then return end
        if Human.Health <= 0 then return end

        local RootAttachment = Root:FindFirstChild("RootAttachment")
        if not RootAttachment then return end

        Debounce = true
        Awning:SetAttribute("Launched", true)

		local IncomingVelocity = Root.AssemblyLinearVelocity
		local IncomingSpeed = IncomingVelocity.Magnitude
		local IncomingDirection = IncomingSpeed > 0.5 and IncomingVelocity.Unit or Normal

		local ReflectedDirection = (IncomingDirection - 2 * IncomingDirection:Dot(Normal) * Normal).Unit

        local LaunchPower = RNG:NextInteger(Power.Min, Power.Max)

		if Root:FindFirstChild("AwningVelocity") then Root.AwningVelocity:Destroy() end

        local AwningVelocity = Instance.new("LinearVelocity")
        AwningVelocity.Name = "AwningVelocity"
        AwningVelocity.MaxForce = 1000000
        AwningVelocity.Attachment0 = RootAttachment
        AwningVelocity.VectorVelocity = ReflectedDirection * LaunchPower
        AwningVelocity.Parent = Root

        Debris:AddItem(AwningVelocity, CLEAN_TIME)

        task.delay(COOLDOWN, function()
            Awning:SetAttribute("Launched", false)
            Debounce = false
        end)
    end)
end

return BounceAwning