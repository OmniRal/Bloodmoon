-- OmniRal

local UnitService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local New = require(ReplicatedStorage.Source.Pronghorn.New)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AllUnits: {
	[Player | Model]: {
		Avatar: Model, -- Reference the units avatar model. Mostly applies to players and their characters
		Dead: boolean, 
		Folder: Folder?, -- Reference for their value folder which reflects the whatever values the server has; easy access for the client to (only) read their values 
		Connections: {RBXScriptConnection}, -- Potentially will need later
		
		Values: {
			Attributes: {Base: {[string]: number}, Offsets: {[string]: number}},
			States: {[string]: {Active: boolean, Point: string | CFrame}},
			Effects: {[string]: {
				Active: boolean, 
				StartedAt: number, 
				Duration: number, 
				IsDebuff: boolean?,
				Attribute: {[string]: number},
				States: {[string]: {Active: boolean, Point: string | CFrame?}},
			}?
		},
	},
	
	History: {
		{TimeStamp: number, Action: "Damage" | "Heal", Amount: number,}?
	}
}
} = {}

local UnitFolder: Folder -- Move all the players' avatars and units into this folder

local ValueDefinitions: {
	Attributes: {
		[string]: {
			Min: number, -- The lowest this attribute can go
			Max: number,  -- And the highest
			Default: number, -- What all units start off with; unless overriden
			Modifiable: boolean?, -- When TRUE, this attribute will have an Offset value created for it, that can be changed by buffs and debuffs
			HasGain: boolean?, -- When TRUE, this attribute will naturally go up by whatever the DefaultGain is
			DefaultGain: number? -- This can also be overriden
		}
	},
	States: {
		[string]: {
			Priority: number, -- How the players UI decides which buffs or debuffs with these states get shown first.
			-- If 0, it will NEVER be displayed
			
			Point: {Type: "String" | "CFrame"}?, -- If this state has a CFrame or string (for UnitNames) associated with it. 
			--Example: aggression making the unit move towards a specific point or other unit
			
			Fn: (...any) -> (...any)? -- If any specific action should happen
		}
	}
} = {
	-- Number values
	-- Examples: health, mana, damage, walkspeed
	Attributes = {
		Health = {Default = 100, Min = 0, Max = math.huge, Modifiable = true, HasGain = true, DefaultGain = 1},
		Stamina = {Default = 100, Min = 0, Max = math.huge, Modifiable = false, HasGain = true, DefaultGain = 2},
		WalkSpeed = {Default = 10, Min = 0, Max = 20, Modifiable = true}
	},
	
	-- Bool values
	-- Examples: stunned, rooted,
	States = {
		Stunned = {Priority = 100},
		Rooted = {Priority = 90},
		Hidden = {Priority = 0}
	},
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function NewValuesFolder(ThisUnit: Player | Model, StartingAttributes: {[string]: number}?)
	if not AllUnits[ThisUnit] then return end
	
	local NewFolder = New.Instance("Folder", "UnitValues", AllUnits[ThisUnit].Avatar)
	
	-- Attributes
	local AttributeStorage = New.Instance("Configuration", "Attributes", NewFolder)
	for Name, Data in ValueDefinitions.Attributes do
		AttributeStorage:SetAttribute(Name, if StartingAttributes and StartingAttributes[Name] then StartingAttributes[Name] else Data.Default)
	end
	
	-- States
	local StatesStorage = New.Instance("Configuration", "States", NewFolder)
	for Name, Data in ValueDefinitions.States do
		StatesStorage:SetAttribute(Name, false)
		if not Data.Point then continue end
		
		if Data.Point == "String" then
			-- Other unit pointer based on a string (The units name)
			StatesStorage:SetAttribute(Name .. "_Point", "")
		else
			-- This points to a specific location
			-- Kept as a CFrame for flexibility
			StatesStorage:SetAttribute(Name .. "_Point", CFrame.new(0, 0, 0))
		end
	end
	
	-- Effects folder to store buffs and debuffs
	New.Instance("Folder", "Effects", NewFolder)
	
	AllUnits[ThisUnit].Folder = NewFolder
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function UnitService.AddUnit(Unit: Player | Model, StartingAttributes: {[string]: number}?): boolean
	warn("Unit Service added - ", Unit)
	
	if AllUnits[Unit] then return false end
	
	AllUnits[Unit] = {
		Avatar = nil, 
		Dead = false, 
		Connections = {},
		Values = {
			Attributes = {Base = {}, Offsets = {}},
			States = {},
			Effects = {},
		},
		History = {}
	}

	-- Store base values into the units data
	-- Attributes
	for Name, Data in ValueDefinitions.Attributes do
		AllUnits[Unit].Values.Attributes.Base[Name] = if StartingAttributes and StartingAttributes[Name] then StartingAttributes[Name] else Data.Default
	end
	
	-- States
	for Name, Data in ValueDefinitions.States do
		AllUnits[Unit].Values.States[Name] = {Active = false, Point = ""}
		if not Data.Point then continue end
		if Data.Point ~= "CFrame" then continue end
		AllUnits[Unit].Values.States[Name].Point = CFrame.new(0, 0, 0)
	end
	
	if Unit:IsA("Player") then
		-- Handle players
		task.spawn(function()
			-- Make sure the player's character exists first
			while true do
				task.wait(0.25)
				if not Unit.Character then continue end
				break
			end
			
			local Char = Unit.Character
			
			AllUnits[Unit].Avatar = Char
			Char.Parent = UnitFolder

			NewValuesFolder(Unit)
		end)
	else
		-- Handle non-players
		Unit.Parent = UnitFolder
		NewValuesFolder(Unit)
	end
	
	return true
end

function UnitService.PlayerAdded(Player: Player)
	Player.CharacterAdded:Connect(function()
		if UnitService.AddUnit(Player) then return end
		
		AllUnits[Player].Dead = false
		NewValuesFolder(Player)
	end)
	
	task.delay(1, function()
		-- Prevent AddUnit from running twice on the same player
		if AllUnits[Player] then return end
		UnitService.AddUnit(Player)
	end)
end

function UnitService:Init()
	UnitFolder = New.Instance("Folder", "Units", Workspace)
end

function UnitService:Deferred()
end

return UnitService