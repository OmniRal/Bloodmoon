-- OmniRal

local QueueService = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TIME_TO_RESOLVE = 0.06

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Variables
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local AllQueues: {
    [string | Instance]: {
        List: {{Player: Player, Action: string}},
        ResolveAction: () -> (),
        OnGoing: boolean,
    }
} = {}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function ResolveQueue(Identity: string | Instance)
    local ThisQueue = AllQueues[Identity]
    if not ThisQueue then return end
    if not ThisQueue.ResolveAction then return end

    local RunQueue: RBXScriptConnection?
    local TimePassed = 0
    local IsResolved = false

    RunQueue = RunService.Heartbeat:Connect(function(DeltaTime: number)
        if not RunQueue then return end
        
        TimePassed += DeltaTime
        if TimePassed < TIME_TO_RESOLVE then return end
        if not IsResolved then return end

        IsResolved = true

        ThisQueue.ResolveAction()

        RunQueue:Disconnect()
    end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Add an action to a queue
-- @Identity = How to identify the queue
-- @Player = Which player is trying to do this action
-- @Action = The name of the action they are trying to perform
-- @ResolveAction = What happens when the queue has picked a player to perform an action
-- @OnGoing = If the queue should be always be running; this OFF by default
function QueueService.Add(Identity: string | Instance, Player: Player, Action: string, ResolveAction: () -> ()?, OnGoing: boolean?)
    if not AllQueues[Identity] then
        AllQueues[Identity] = {List = {}, ResolveAction = ResolveAction, OnGoing = OnGoing}
    end
    
    table.insert(AllQueues[Identity].List, {Player = Player, Action = Action})

    if OnGoing then return end

    ResolveQueue(Identity)
end

function QueueService:Init()

end

return QueueService