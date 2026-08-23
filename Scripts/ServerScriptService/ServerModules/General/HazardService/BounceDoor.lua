-- OmniRal

local BounceDoor = {}

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

function BounceDoor.Setup(Door: any)
	local Power = Door:GetAttribute("Power") :: NumberRange
	local Side = if Door.Side.Position.X < 0 then -1 else 1 
    local Normal = (Door.CFrame * CFrame.Angles(0, math.pi / 4 * -Side, 0)).LookVector
    local Debounce = false

    Door:SetAttribute("Launched", false)

    Door.Touched:Connect(function(Hit: BasePart)
        if Debounce then return end
        if not Hit then return end
        if not Hit.Parent then return end
        local Human, Root = Hit.Parent:FindFirstChild("Humanoid") :: Humanoid, Hit.Parent:FindFirstChild("HumanoidRootPart") :: BasePart
        if not Human or not Root then return end
        if Human.Health <= 0 then return end

        local RootAttachment = Root:FindFirstChild("RootAttachment")
        if not RootAttachment then return end

        Debounce = true
        Door:SetAttribute("Launched", true)

		local IncomingVelocity = Root.AssemblyLinearVelocity
		local IncomingSpeed = IncomingVelocity.Magnitude
		local IncomingDirection = IncomingSpeed > 0.5 and IncomingVelocity.Unit or Normal

		local ReflectedDirection = (IncomingDirection - 2 * IncomingDirection:Dot(Normal) * Normal).Unit

        local LaunchPower = RNG:NextInteger(Power.Min, Power.Max)

		if Root:FindFirstChild("DoorVelocity") then Root.DoorVelocity:Destroy() end

        local DoorVelocity = Instance.new("LinearVelocity")
        DoorVelocity.Name = "DoorVelocity"
        DoorVelocity.MaxForce = 1000000
        DoorVelocity.Attachment0 = RootAttachment
        DoorVelocity.VectorVelocity = ReflectedDirection * LaunchPower
        DoorVelocity.Parent = Root

        Debris:AddItem(DoorVelocity, CLEAN_TIME)

        task.delay(COOLDOWN, function()
            Door:SetAttribute("Launched", false)
            Debounce = false
        end)
    end)

    Door.CanCollide = false
end

return BounceDoor