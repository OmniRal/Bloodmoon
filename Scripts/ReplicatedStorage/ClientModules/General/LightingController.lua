-- OmniRal

local LightingController = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------`

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Types
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

export type LightingSetting = {
	Lighting: {
		Ambient: Color3?,
		Brightness: number?,
		ColorShift_Bottom: Color3?,
		ColorShift_Top: Color3?,
		EnvironmentDiffuseScale: number?,
		EnvironmentSpecularScale: number?,
		OutdoorAmbient: Color3?,
		ClockTime: number?,
		GeographicLatitude: number?,
		ExposureCompensation: number?,
	}?,

	Atmosphere: {
		Density: number?, 
		Offset: number?,
		Color: Color3?,
		Decay: Color3?,
		Glare: number?,
		Haze: number?,
	}?,

	Bloom: {
		Enabled: boolean?,
		Intensity: number?,
		Size: number?,
		Threshold: number?,
	}?,

	Blur: {
		Enabled: boolean?,
		Size: number?,
	}?,

	ColorCorrection: {
		Enabled: boolean?,
		Brightness: number?,
		Contrast: number?,
		Saturation: number?,
		TintColor: Color3?,
	}?,

	DepthOfField: {
		Enabled: boolean?,
		FarIntensity: number?,
		FocusDistance: number?,
		InFocusRadius: number?,
		NearIntensity: number?,
	}?,

	SunRays: {
		Enabled: boolean?,
		Intensity: number?,
		Spread: number?
	}?
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------`
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Store specific lighting settings here with an attached name
-- Easy access
local SavedLightingSettings: {[string]: LightingSetting} = {
	["MoonStart"] = {
		Lighting = {
			Ambient = Color3.fromRGB(85, 125, 208),
			Brightness = 3,
			ColorShift_Bottom = Color3.fromRGB(51, 56, 189),
			ColorShift_Top = Color3.fromRGB(73, 126, 236),
			EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 1,
			OutdoorAmbient = Color3.fromRGB(45, 60, 146),
			ClockTime = 0,
			GeographicLatitude = 0,
			ExposureCompensation = 0.2,
		},

		Atmosphere = {
			Density = 0.6,
			Offset = 1,
			Color = Color3.fromRGB(56, 106, 209),
			Decay = Color3.fromRGB(106, 112, 125),
			Glare = 0,
			Haze = 0.01,
		},

		Bloom = {
			Enabled = true,
			Intensity = 1,
			Size = 24,
			Threshold = 2,
		},

		Blur = {
			Enabled = false, 
			Size = 0
		},

		ColorCorrection = {
			Enabled = true,
			Brightness = 0.05,
			Contrast = 0.05,
			Saturation = 0,
			TintColor = Color3.fromRGB(255, 255, 255),
		},

		DepthOfField = {
			Enabled = false,
			FarIntensity = 1,
			FocusDistance = 0.05,
			InFocusRadius = 30,
			NearIntensity = 0.75,
		},

		SunRays = {
			Enabled = true,
			Intensity = 0.01,
			Spread = 0.1
		}
	}
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function LightingController.GetSetting(ThisSetting: string): LightingSetting
	return SavedLightingSettings[ThisSetting]
end

-- Change lighting to a specific setting
-- @TransitionTime = If it should tween it
function LightingController.Set(NewSetting: LightingSetting, TransitionTime: number?)
	if not NewSetting then return end
	for Name, Data in NewSetting do
		local Object = Lighting -- Handle the Lighting object itself

		if Name ~= "Lighting" then
			-- Handle objects inside Lighting
			Object = Lighting:FindFirstChild(Name)
			if not Object then warn(Name, " does not exist in Lighting!"); continue end
		end

		if not Object then continue end

		local TweenList: {[string]: any} = {}

		for Property, Value in Data do
			if not Property or Value == nil then continue end
			if not Object[Property] then warn(Property, " is not a property of ", Name); continue end
			if typeof(Value) ~= "boolean" then
				if TransitionTime then 
					TweenList[Property] = Value
				else
					Object[Property] = Value
				end
			else
				Object[Property] = Value
			end
		end

		if not TransitionTime then continue end
		TweenService:Create(Object, TweenInfo.new(TransitionTime, Enum.EasingStyle.Linear), TweenList):Play()
	end
end

return LightingController