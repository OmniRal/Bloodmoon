-- OmniRal

local PropertyVals = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

-- Creates a separate number value to tween the transparency of UI
-- @This = Typically would be a canvas group or a frame, but tehcnically can be anything with transparency
-- @Property = Optional to pick a specific property
-- @StartingValue = Optional starting value
-- @Name = Optional alternative name for the value
function PropertyVals.AddTransparencyVal(This: any, Property: string?, StartingValue: number?, Name: string?)
	if not This then warn(This, "does not exist!"); return end
	
	local ThisProperty = Property
	
	-- If no property provided, use a default one
	if not Property then
		if This:IsA("CanvasGroup") then
			ThisProperty = "GroupTransparency"
		elseif This:IsA("Frame") then
			ThisProperty = "BackgroundTransparency"
		end
	end
	
	if not This[ThisProperty] then warn(Property, "does not exist on ", This); return end
	
	local Val = Instance.new("NumberValue")
	Val.Name = Name or "TransparencyVal"
	Val.Value = StartingValue or This[Property]
	Val.Parent = This

	Val.Changed:Connect(function()
		if not This or not ThisProperty then return end
		if not This[ThisProperty] then return end
		This[ThisProperty] = Val.Value
	end)
end

-- Creates a separate color3 value to control a canvas groups groupcolor3
function PropertyVals.AddGroupColorVal(Canvas: CanvasGroup, StartingValue: Color3?, Name: string?)
	if not Canvas then warn(Canvas, "does not exist!"); return end
	
	local Val = Instance.new("Color3Value")
	Val.Name = Name or "GroupColorVal"
	Val.Value = StartingValue or Canvas.GroupColor3
	Val.Parent = Canvas
	
	Val.Changed:Connect(function()
		if not Canvas then return end
		Canvas.GroupColor3 = Val.Value
	end)
end

return PropertyVals