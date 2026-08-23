-- OmniRal

local Utility = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Remotes = require(ReplicatedStorage.Source.Pronghorn.Remotes)

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

-- Formats time into something like 01 / 02 / 1993
function Utility.FormatTime(TimeStamp: number?, European: boolean?)
    TimeStamp = TimeStamp or os.time()
    if not European then
        return os.date("!%m / %d / %Y", TimeStamp)
    else
        return os.date("!%d / %m / %Y", TimeStamp)
    end
end

function Utility.CheckRemotesLoaded(List: {string})
	while true do
		task.wait()
		local MissingAny = false
		for _, Name in List do
			if Remotes.Client[Name] then continue end
			MissingAny = true
		end

		if not MissingAny then break end
	end
end

function Utility.ConvertSecondsToHMS(TotalSeconds: number, CutHours: boolean?)
	local Hours = math.floor(TotalSeconds / 3600)
	local Minutes = math.floor((TotalSeconds % 3600) / 60)
	local Seconds = math.floor(TotalSeconds % 60)

	if Hours > 0 then
		if Hours < 10 then Hours = "0" .. tostring(Hours); else Hours = tostring(Hours); end
	else
		Hours = "00"
	end

	if Minutes > 0 then
		if Minutes < 10 then Minutes = "0" .. tostring(Minutes); else Minutes = tostring(Minutes) end
	else
		Minutes = "00"
	end

	if Seconds > 0 then
		if Seconds < 10 then Seconds = "0" .. tostring(Seconds); else Seconds = tostring(Seconds) end
	else
		Seconds = "00"
	end
	
	if not CutHours then
		return Hours .. ":" .. Minutes .. ":" .. Seconds
	else
		return Minutes .. ":" .. Seconds
	end
end

function Utility.ChangeModelTransparency(Model: Model, To: number, Ignore: {string}?, GetDescendants: boolean?)
    if not Model then return end
    
    local List
    if not GetDescendants then
        List = Model:GetChildren()
    else
        List = Model:GetDescendants()
    end
    
    for _, Part in List do
        local IgnorePart = false
        if Ignore then
            for _, Name in Ignore do
                if Part.Name ~= Name then continue end
                IgnorePart = true
                break
            end
        end
        if IgnorePart then continue end
        if not Part:IsA("BasePart") then continue end

        if To >= 1 then
            Part:SetAttribute("OriginalTransparency", Part.Transparency)
            Part.Transparency = To
        elseif To <= 0 then
            if Part:GetAttribute("OriginalTransparency") ~= nil then
                Part.Transparency = Part:GetAttribute("OriginalTransparency")
            else
                Part.Transparency = 0
            end
        else
            Part.Transparency = To
        end

        for _, Image in Part:GetChildren() do
            if not Image then continue end
            if not Image:IsA("Decal") and not Image:IsA("Texture") then continue end
            if To >= 1 then
                Image:SetAttribute("OriginalTransparency", Image.Transparency)
                Image.Transparency = To
            elseif To <= 0 then
                if Image:GetAttribute("OriginalTransparency") ~= nil then
                    Image.Transparency = Image:GetAttribute("OriginalTransparency")
                else
                    Image.Transparency = 0
                end
            else
                Image.Transparency = To
            end 
        end
    end
end

function Utility.CreateDot(CF: CFrame, Size: Vector3, Shape: Enum.PartType, Color: Color3?, Duration: number?, Parent: Instance?)
    local Dot = Instance.new("Part")
    Dot.Name = "Dot"
    Dot.Anchored = true
    Dot.CanCollide = false
    Dot.CanQuery = false
    Dot.CanTouch = false
    Dot.CFrame = CF
    Dot.Material = Enum.Material.Neon
    Dot.Size = Size or Vector3.new(2, 2, 2)
    Dot.Shape = Shape
    Dot.Color = Color or Color3.fromRGB(230, 30, 40)
    Dot.Parent = Parent or Workspace

    if Duration then
        Debris:AddItem(Dot, Duration)
    end

    return Dot
end

function Utility:GetAnimationSpeedFromAttackSpeed(AttackSpeed: number)
    return AttackSpeed / 100
end

function Utility:CheckForItems(List: {}, From: CFrame, Range: number)
    for _, Item: Model in Workspace.Items:GetChildren() do
        if not Item then continue end
        if table.find(List, Item) then continue end

        local Root = Item.PrimaryPart
        if not Root then continue end

        local Distance = (From.Position - Root.Position).Magnitude
        if Distance > Range then continue end

        table.insert(List, Item)
    end

    return List
end

function Utility:Init()
    -- Require all the children modules
    for _, Module in script:GetChildren() do
        if not Module:IsA("ModuleScript") then continue end
        Utility[Module.Name] = require(Module)
    end
end

function Utility:Deferred()
end

return Utility