-- OmniRal

local BounceBumper = {}

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

function BounceBumper.Setup(Bumper: BasePart)
	local Power = Bumper:GetAttribute("Power") :: NumberRange
	local Normal = Bumper.CFrame.LookVector
    local Debounce = false

    Bumper:SetAttribute("Launched", false)

    Bumper.Touched:Connect(function(Hit: BasePart)
        if Debounce then return end
        if not Hit then return end
        if not Hit.Parent then return end
        local Human, Root = Hit.Parent:FindFirstChild("Humanoid") :: Humanoid, Hit.Parent:FindFirstChild("HumanoidRootPart") :: BasePart
        if not Human or not Root then return end
        if Human.Health <= 0 then return end

        local RootAttachment = Root:FindFirstChild("RootAttachment")
        if not RootAttachment then return end

        Debounce = true
        Bumper:SetAttribute("Launched", true)

		local IncomingVelocity = Root.AssemblyLinearVelocity
		local IncomingSpeed = IncomingVelocity.Magnitude
		local IncomingDirection = IncomingSpeed > 0.5 and IncomingVelocity.Unit or Normal

		local ReflectedDirection = (IncomingDirection - 2 * IncomingDirection:Dot(Normal) * Normal).Unit

        local LaunchPower = RNG:NextInteger(Power.Min, Power.Max)

		if Root:FindFirstChild("BumperVelocity") then Root.BumperVelocity:Destroy() end

        local BumperVelocity = Instance.new("LinearVelocity")
        BumperVelocity.Name = "BumperVelocity"
        BumperVelocity.MaxForce = 1000000
        BumperVelocity.Attachment0 = RootAttachment
        BumperVelocity.VectorVelocity = ReflectedDirection * LaunchPower
        BumperVelocity.Parent = Root

        Debris:AddItem(BumperVelocity, CLEAN_TIME)

        task.delay(COOLDOWN, function()
            Bumper:SetAttribute("Launched", false)
            Debounce = false
        end)
    end)
end

return BounceBumper