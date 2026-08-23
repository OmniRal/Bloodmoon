-- OmniRal

-- Server control over a players camera.

local CameraService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Sets the camera type for a single player.
-- @Player: The player to change the camera type for.
-- @To: 0 = "None" / Default, 1 = "ThirdPerson"
function CameraService:SetCameraType(Player: Player, To: number)
    Remotes.Server.CameraService.SetCameraType:Fire(Player, To)
end

-- Sets the camera type for all players.
-- @To: 0 = "None" / Default, 1 = "ThirdPerson"
function CameraService:SetAllCameraType(To: number)
    Remotes.Server.CameraService.SetCameraType:FireAll(To)
end

-- Apply a camera shake to a single player.
function CameraService:ApplyShake(Player: Player, Speed: number, Damper: number, Power: Vector3)
    if not Player then return end
    Remotes.Server.CameraService.CameraShake:Fire(Player, Speed, Damper, Power)
end

-- Apply a camera shake to all players.
function CameraService:ApplyShakeToAllPlayers(Speed: number, Damper: number, Power: Vector3)
    Remotes.Server.CameraService.CameraShake:FireAll(Speed, Damper, Power)
end

function CameraService:Init()
    Remotes.Server:CreateToClient("SetCameraType", {}, "Reliable")
    Remotes.Server:CreateToClient("CameraShake", {}, "Unreliable")
end

return CameraService