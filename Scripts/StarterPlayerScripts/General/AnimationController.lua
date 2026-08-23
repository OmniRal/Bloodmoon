-- OmniRal

local AnimationController = {}

-- OmniRal

local Template = {}

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

AnimationController.Tracks = {}
AnimationController.AnimTracks = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Stops the animation track.
function AnimationController.CutAnim(KeyName: string)
    if AnimationController.AnimTracks[KeyName] then
        if AnimationController.AnimTracks[KeyName].T then
            AnimationController.AnimTracks[KeyName].T:Stop()
            AnimationController.AnimTracks[KeyName].T = nil
            AnimationController.AnimTracks[KeyName].CanPlay = true
        end
    end
end

-- Plays a new animation.
function AnimationController.PlayNew(Character: any, KeyName: string, AnimName: string, Override: boolean, Speed: number, KeyframeFunc: (string, string, {}?) -> ()?, ...)
    if not Character or not AnimationController.Tracks[KeyName] or not AnimationController.AnimTracks[KeyName] then return end
    if not AnimationController.Tracks[KeyName][AnimName] then return end
    local Tracks = AnimationController.Tracks[KeyName]
    local AnimTrack = AnimationController.AnimTracks[KeyName]

    local Params = {...}

    if AnimTrack.CanPlay or Override then
        if AnimTrack.T ~= nil then
            AnimTrack.T:Stop()
            AnimTrack.T = nil
        end

        if Tracks[AnimName].Track ~= nil then
            if not Tracks[AnimName].Set then
                Tracks[AnimName].Set = true

                Tracks[AnimName].Track.KeyframeReached:Connect(function(Keyframe: string)
                    if not KeyframeFunc then return end
                    KeyframeFunc(Keyframe, AnimName, unpack(Params))
                end)
            end

            AnimTrack.T = Tracks[AnimName].Track
            AnimTrack.T:Play()
            AnimTrack.T:AdjustSpeed(Speed)
        end
    end
end

-- Load in all the animations when the player first spawns.
-- @Character: The character to load the animations onto.
-- @KeyName: The key name to be kept and used in the table.
-- @AnimationsList: The table of animations to load.
function AnimationController.LoadAnimations(Character: any, KeyName: string, AnimationsList: {[string]: {ID: number, Priority: Enum.AnimationPriority, Looped: boolean?}})
	if not Character or not KeyName or not AnimationsList then return end
    AnimationController.Tracks[KeyName] = {}
    AnimationController.AnimTracks[KeyName] = {T = nil, CanPlay = true}

    for Name, Id in pairs(AnimationsList) do
        local NewAnimation = Instance.new("Animation")
        NewAnimation.AnimationId = "rbxassetid://" .. AnimationsList[Name].ID
        local NewTrack = Character.Humanoid:LoadAnimation(NewAnimation)
        NewTrack.Priority = AnimationsList[Name].Priority
        if AnimationsList[Name].Looped ~= nil then
            NewTrack.Looped = AnimationsList[Name].Looped
        end
        

        AnimationController.Tracks[KeyName][Name] = {Track = NewTrack, Set = false}
    end

    print("Loaded Animation Set: ", KeyName)
end

return AnimationController