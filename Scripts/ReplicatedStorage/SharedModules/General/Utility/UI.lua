-- OmniRal

local UI_Util = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)
--local ColorPalette = require(ReplicatedStorage.Source.SharedModules.Info.ColorPalette)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local PLACEHOLDER_HEADSHOT = "rbxassetid://136066080154281"

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CurrentCamera = Workspace.CurrentCamera

--local AnimTime = UI_Info.BaseAnimTime

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function UI_Util.GetCommentSizeY(): number
	return CurrentCamera.ViewportSize.Y / 12
end

function UI_Util.GetPlayerHeadshot(UserID: number): (string, boolean?)
	local Image, Loaded = Players:GetUserThumbnailAsync(UserID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	
	if Loaded then
		return Image
	else
		return PLACEHOLDER_HEADSHOT, true
	end
end

function UI_Util.WaitForValidViewport()
	while CurrentCamera.ViewportSize == Vector2.zero or CurrentCamera.ViewportSize == Vector2.new(1, 1) do
		task.wait()
	end
	task.wait()
end

-- @Scroller = The scrolling frame to update
-- @GridLayout = The UIGridLayout that is inside the scrolling frame
-- @TotalCells = How many cells are in the scrolling frame; calculate canvas size y with this
-- @NumCellsHorizontal = How many cells should there be across the frame
-- @Style = What size style each cell should be
function UI_Util.UpdateSingleScroller(Scroller: ScrollingFrame, GridLayout: UIGridLayout, TotalCells: number, NumCellsHorizontal: number, Style: "Square" | "Portrait")
	local Width = Scroller.AbsoluteCanvasSize.X - (Scroller.ScrollBarThickness)
	local Padding = GridLayout.CellPadding
	
	local CellSize_X = Width / NumCellsHorizontal - (Padding.X.Offset * (NumCellsHorizontal - 1))
	local CellSize_Y = CellSize_X
	
	local NumCellsVertical = math.ceil(TotalCells / NumCellsHorizontal)
	
	if Style == "Portrait" then
		CellSize_Y *= 1.5
	end
	
	GridLayout.CellSize = UDim2.fromOffset(CellSize_X, CellSize_Y)
	Scroller.CanvasSize = UDim2.fromOffset(0, NumCellsVertical * CellSize_Y + (Padding.Y.Offset * (NumCellsVertical - 1)))
end

-- Similar to the above, but uses ListLayout instead
function UI_Util.UpdateSingleScroller_B(Scroller: ScrollingFrame, ListLayout: UIListLayout, Axis: "X" | "Y"): number
	local TotalLength, TotalItems = 0, 0
	
	for _, Item in Scroller:GetChildren() do
		if Item == ListLayout or string.find(Item.Name, "OG_") or string.find(Item.Name, "OG") then continue end
		TotalLength += Item.AbsoluteSize[Axis]
		TotalItems += 1
	end
	
	local FinalLength = TotalLength + (math.clamp(TotalItems - 1, 0, math.huge) * ListLayout.Padding.Offset)
	if Axis == "X" then
		Scroller.CanvasSize = UDim2.fromOffset(FinalLength, 0)
	else
		Scroller.CanvasSize = UDim2.fromOffset(0, FinalLength)
	end
	
	return TotalItems
end

-- Creates an effect where the edges of the scroll frame fade
-- Scroller (ScrollingFrame) must be inside Container (CanvasGroup) to work
-- @Axis = Which axis to use
-- @FadePercent = Min is 0.02; Max is 0.2; how much fade to apply
function UI_Util.AddAutoFadingForScroller(Container: CanvasGroup, Scroller: any, Axis: "X" | "Y", FadePercent: number)
	if not Container or not Scroller then return end
	local Gradient = Container:FindFirstChild("Gradient") :: UIGradient
	if not Gradient then return end
	
	local function UpdateTransparency()
		if not Container or not Scroller or not Gradient then return end
		
		local Length = Scroller.AbsoluteCanvasSize[Axis]
		local MaxScroll = Length - Scroller.AbsoluteSize[Axis]
		
		if MaxScroll <= 1 then
			Gradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0)}
			return
		end
		
		local EdgePercent = 0.01
		FadePercent = math.clamp(FadePercent or 0.05, 0.02, 0.2)
		
		if Scroller.CanvasPosition[Axis] <= MaxScroll * EdgePercent then
			-- Fade at the bottom / right
			Gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1 - FadePercent, 0),
				NumberSequenceKeypoint.new(1, 1)
			}
			
		elseif Scroller.CanvasPosition[Axis] >= MaxScroll - (MaxScroll * EdgePercent) then
			-- Fade at the top / left
			Gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(FadePercent, 0),
				NumberSequenceKeypoint.new(1, 0)
			}
			
			
		else
			-- Fade on both ends
			Gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(FadePercent, 0),
				NumberSequenceKeypoint.new(1 - FadePercent, 0),
				NumberSequenceKeypoint.new(1, 1)
			}
			
		end
	end
	
	Scroller:GetPropertyChangedSignal("CanvasSize"):Connect(function()
		UpdateTransparency()
	end)
	
	Scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		UpdateTransparency()
	end)
end

-- Converts a text like this:
-- "This is great!"
-- to
-- "T H I S   I S   G R E A T !"
-- Each character is uppercased, spaces are added in between characters, and spaces are converted into 3 spaces
function UI_Util.CapSpaceText(Text: string): string
	local Result = {}
	
	for n = 1, string.len(Text) do
		local Char = string.sub(Text, n, n)
		
		if Char == " " then
			table.insert(Result, "   ")
			
		else
			table.insert(Result, string.upper(Char))
			if n < string.len(Text) then
				table.insert(Result, " ")
			end
		end
	end
	
	return table.concat(Result)
end

return UI_Util