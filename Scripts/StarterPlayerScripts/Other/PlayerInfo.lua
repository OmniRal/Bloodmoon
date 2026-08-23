-- OmniRal

local PlayerInfo = {}

PlayerInfo.Data = nil

PlayerInfo.Human = nil :: Humanoid?
PlayerInfo.Root = nil :: BasePart?
PlayerInfo.Dead = false
PlayerInfo.IsRunning = false


PlayerInfo.MoveVector = Vector3.new(0, 0, 0)

PlayerInfo.Music = nil
PlayerInfo.Sounds = nil

PlayerInfo.Grounded = {
    State = false,
    Surface = nil,
    Position = Vector3.new(0, 0, 0),
    Normal = Vector3.new(0, 0, 0),
    LastCheck = os.clock(),
    Rate = 0.2,
}

PlayerInfo.UnitValues = nil

PlayerInfo.CurrentLevel = -1
PlayerInfo.CurrentMaxXP = 0
PlayerInfo.CurrentXP = 0
PlayerInfo.AddXP = 0

PlayerInfo.CurrentPoints = 0
PlayerInfo.CurrentStreak = 0 
PlayerInfo.CurrentMultiplier = 0

PlayerInfo.PushStarted = false
PlayerInfo.PushDone = 0

PlayerInfo.DodgeDone = 0

return PlayerInfo