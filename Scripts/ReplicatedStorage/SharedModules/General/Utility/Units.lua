-- OmniRal

local Units = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

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

local UnitParts = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Units.CheckGrounded(Unit: Model, Root: BasePart, Params: RaycastParams): (boolean?, string?)
    if not Unit or not Root then return end

    local Grounded, Surface = false, nil

    local RayDown = Workspace:Raycast(Root.Position, CFrame.new(Root.Position).UpVector * -7, Params)
    if not RayDown then return end
    if not RayDown.Instance then return end
    Grounded = true
    Surface = RayDown.Instance

    return Grounded, Surface
end

function Units.CheckForUnits(Type: "Players" | "Bots" | "All", List: {}, From: CFrame, Range: number)
    for _, Unit in Workspace.Units:GetChildren() do
        if not Unit then continue end

        local CheckUnit = false
        if Type == "Players" then
            if CollectionService:HasTag(Unit, "Bot") then continue end
            CheckUnit = true
        
        elseif Type == "Bots" then
            if not CollectionService:HasTag(Unit, "Bot") then continue end
            CheckUnit = true

        else
            CheckUnit = true
        end
           
        if not CheckUnit then continue end
        if table.find(List, Unit) then continue end

        local Human, Root = Unit:FindFirstChild("Humanoid") :: Humanoid, Unit:FindFirstChild("HumanoidRootPart") :: BasePart
        if not Human or not Root then continue end
        if Human.Health <= 0 then continue end
        local Distance = (From.Position - Root.Position).Magnitude
        if Distance > Range then continue end

        table.insert(List, Unit)
    end

    return List
end

function Units.BasicUnitCheck(Unit: Model, Player: Player)
    if not Unit then return end
    if Unit == Player.Character or Unit:GetAttribute("Team") == Player:GetAttribute("Team") then return end
    local EnemyHuman, EnemyRoot, EnemyAttributes = Unit:FindFirstChild("Humanoid"), Unit:FindFirstChild("HumanoidRootPart"), Unit:FindFirstChild("UnitAttributes")
    if not EnemyHuman or not EnemyRoot or not EnemyAttributes then return end
    if EnemyHuman.Health <= 0 then return end

    return EnemyHuman, EnemyRoot, EnemyAttributes
end

function Units.ClearUnitParts()
    table.clear(UnitParts)
end

function Units.SetUnitTransparency(Unit: Model, To: number)
    if not Unit then
        if UnitParts[Unit] then
            UnitParts[Unit] = nil
        end
        return
    end

    if Unit:GetAttribute("CurrentTransparency") == To then return end

    local List
    if not UnitParts[Unit] then
        UnitParts[Unit] = {}
        for _, BasePart in Unit:GetDescendants() do
            if not BasePart then continue end
            if not BasePart:IsA("BasePart") then continue end
            if BasePart.Name == "HumanoidRootPart" then continue end
            table.insert(UnitParts[Unit], BasePart)
        end
        List = UnitParts[Unit]
    else
        List = UnitParts[Unit]
    end

    for _, BasePart in List do
        if not BasePart then continue end
        if not BasePart:GetAttribute("TrueTransparency") then
            BasePart.Transparency = To
        else
            BasePart.Transparency = BasePart:GetAttribute("TrueTransparency")
        end
    end
end

return Units