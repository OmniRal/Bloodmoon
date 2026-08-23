-- OmniRal

local DragSlider = {}

-- Sets up the horizontal (and vertical in future?) draggable sliders

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local BasicInteractions = require(ReplicatedStorage.Source.ClientModules.UI.Components.BasicInteractions)

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

-- @Slider = The slider to set up
-- @Fn = This runs whenever the slider gets moved
-- @Range = The min and max value that the slider represents
-- @Increments = How many pieces Range (must exist) should be cut up in
-- @StartValue = Moves the slider to this start value
function DragSlider.AddSlider(Slider: Frame, Fn: (number) -> (), Range: NumberRange?, Increments: number?, StartValue: number?)
	local Bar = Slider:FindFirstChild("Bar") :: Frame
	if not Bar then warn("Missing Bar in Slider!"); return end
	
	local Line, Button = Bar:FindFirstChild("Line") :: Frame, Bar:FindFirstChild("Button") :: ImageButton
	if not Line or not Button then warn("Missing Line or Button in Slider!"); return end
	
	local FixedPositions: {number} = {}
	Slider:SetAttribute("Val", StartValue)
	Slider:SetAttribute("ForceVal", StartValue)

	local function UpdateFixedPositions()
		if not Range or not Increments then return end
		
		-- Cut the line into increments here
		FixedPositions = {0}

		local Inc = 1 / Increments

		for x = 1, Increments do
			local NewPosition = (Line.AbsoluteSize.X) * (Inc * x)
			table.insert(FixedPositions, NewPosition)
		end
	end
	
	local function PositionSlider(ElementPosition: UDim2, StartPosition: Vector3, CurrentPosition: Vector3)
		local Delta = CurrentPosition - StartPosition
		
		if not Range or not Increments then
			-- Free sliding
			Button.Position = UDim2.new(0, math.clamp(ElementPosition.X.Offset + Delta.X, 0, math.round(Line.AbsoluteSize.X)), 0.5, 0)

		else
			-- Fixed sliding
			local DraggingPosition = math.clamp(ElementPosition.X.Offset + Delta.X, 0, math.round(Line.AbsoluteSize.X))

			local NewPosition = 0
			local LastDistance = math.huge

			for _, FPosition: number in ipairs(FixedPositions) do
				local Distance = math.abs(DraggingPosition - FPosition)
				if Distance >= LastDistance then continue end

				LastDistance = Distance
				NewPosition = FPosition
			end

			Button.Position = UDim2.new(0, NewPosition, 0.5, 0)
			local Percent = NewPosition / Bar.AbsoluteSize.X
			Slider:SetAttribute("Val", (if Range then Range.Max else 100) * Percent)
		end
	end
	
	local function FinalizeCalculations()
		local Percent = Button.Position.X.Offset / math.round(Line.AbsoluteSize.X) -- What gets sent back when no Range is given
		local FinalValue = Percent

		if Range then
			-- If Range, calculate
			FinalValue = Range.Min + ((Range.Max - Range.Min) * Percent)
		end

		Fn(FinalValue)
	end
	
	BasicInteractions.AddButton(Button, false, nil, Button, 
		nil, 
		UpdateFixedPositions, 
		function(ElementPosition: UDim2, StartPosition: Vector3, CurrentPosition: Vector3)
			PositionSlider(ElementPosition, StartPosition, CurrentPosition)
			FinalizeCalculations()
		end, 
		nil
	)

	Slider:GetAttributeChangedSignal("ForceVal"):Connect(function()
		local ForceVal = Slider:GetAttribute("ForceVal")
		if not ForceVal then return end
		local Percent = ForceVal / if Range then Range.Max else 100
		local Pos = math.round(Line.AbsoluteSize.X) * Percent

		UpdateFixedPositions()
		Button.Position = UDim2.new(0, Pos, 0.5, 0)
	end)
	
	if not StartValue then return end
	
	local StartPercent = StartValue / if Range then Range.Max else 100
	local StartPos = math.round(Line.AbsoluteSize.X) * StartPercent
	
	UpdateFixedPositions()
	PositionSlider(Button.Position, Vector3.new(0, 0, 0), Vector3.new(StartPos, 0, 0))
end

return DragSlider