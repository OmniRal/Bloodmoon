-- OmniRal

local ErrorMessageUI = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UI_Info = require(ReplicatedStorage.Source.ClientModules.UI.UI_Info)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local OFF_DELAY = 2
local ON_SIZE = UDim2.fromScale(0.35, 0.075)
local OFF_SIZE = UDim2.fromScale(0.25, 0.05)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Message: any?
local OnTween: Tween?
local OffTween: Tween?

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AnimTime = UI_Info.BaseAnimTime

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create a new error message; this does not stack
function ErrorMessageUI.New(Text: string)
	if not Message then return end
	if OnTween then OnTween:Pause(); OnTween:Destroy(); OnTween = nil end
	if OffTween then OffTween:Pause(); OffTween:Destroy(); OffTween = nil end

	Message.Frame.Label.Text = Text
	Message.GroupTransparency = 1
	Message.Size = OFF_SIZE
	Message.Visible = true

	OnTween = TweenService:Create(Message, TweenInfo.new(AnimTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
	{Size = ON_SIZE, GroupTransparency = 0})
	OffTween = TweenService:Create(Message, TweenInfo.new(AnimTime, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, OFF_DELAY), 
	{Size = OFF_SIZE, GroupTransparency = 1})
	if not OnTween or not OffTween then return end

	OnTween.Completed:Connect(function()
		if not OffTween then return end
		OffTween:Play()
	end)

	OffTween.Completed:Connect(function()
		Message.Visible = false
	end)

	OnTween:Play()
end

function ErrorMessageUI.Setup(Gui: ScreenGui)
	if not Gui then return end

	Message = Gui:FindFirstChild("ErrorMessage")
	if not Message then return end

	Message.GroupTransparency = 1
	Message.Visible = false
end

return ErrorMessageUI