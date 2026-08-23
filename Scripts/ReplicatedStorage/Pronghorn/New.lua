--!strict
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local New = {}

-- Services
const HttpService = game:GetService("HttpService")
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

-- Core
const Print = require(script.Parent.Debug).Print
const Warn = require(script.Parent.Debug).Warn

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Types
export type Callback<T...> = (T...) -> ()
export type Connection = {Disconnect: (self: Connection) -> ()}
export type Event<T...> = {
	Fire: (self: Event<T...>, T...) -> ();
	Connect: (self: Event<T...>, callback: Callback<T...>) -> Connection;
	Once: (self: Event<T...>, callback: Callback<T...>) -> Connection;
	Wait: (self: Event<T...>, timeout: number?) -> (boolean, T...);
	DisconnectAll: (self: Event<T...>) -> ();
}
export type TrackedVariable<T> = {
	Get: (self: TrackedVariable<T>) -> T;
	Set: (self: TrackedVariable<T>, value: T) -> ();
	Connect: (self: TrackedVariable<T>, callback: Callback<T, T>) -> Connection;
	Once: (self: TrackedVariable<T>, callback: Callback<T, T>) -> Connection;
	Wait: (self: TrackedVariable<T>, timeout: number?) -> (boolean, T, T);
	WaitFor: (self: TrackedVariable<T>, value: T, timeout: number?) -> (boolean, T, T);
	DisconnectAll: (self: TrackedVariable<T>) -> ();
}
export type InstanceStream<T...> = {
	Instances: {Instance};
	Start: (self: InstanceStream<T...>, players: Player | {Player}, instances: {Instance}) -> string;
	Listen: (self: InstanceStream<T...>, uid: string) -> (Event<T...>, Event<Instance>);
}
type Properties = {[string]: any, Children: {Instance}?, Attributes: {[string]: any}?, Tags: {string}?}

-- Constants
const IS_SERVER = RunService:IsServer()
const IS_CLIENT = RunService:IsClient()
const QUEUED_EVENT_QUEUE_SIZE = 256

-- Objects
const localPlayer = Players.LocalPlayer :: Player

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Parents all children to an `Instance`.
--- @param parent -- The new parent `Instance` of the children.
--- @param children? -- The list of `Instances` to be parented.
function New.Children(parent: Instance, children: {Instance}?): ()
	if children then
		for _, child in children do
			if typeof(child) == "Instance" then
				child.Parent = parent
			end
		end
	end
end

--- Creates and returns an `Event`.
--- @return Event<...any> -- The new `Event`.
function New.Event(): Event<...any>
	const callbacks: {Callback<...any>} = {}
	const waiting: {Callback<...any> | thread} = {}

	const actions: Event<...any> = {
		Fire = function(self: Event<...any>, ...: any): ()
			const currentlyWaiting = table.clone(waiting)
			table.clear(waiting)
			for _, callback in table.clone(callbacks) do
				task.spawn(callback, ...)
			end
			for _, callback in currentlyWaiting do
				if typeof(callback) == "thread" then
					if coroutine.status(callback) ~= "suspended" then continue end
					task.spawn(callback, true, ...)
				else
					task.spawn(callback, ...)
				end
			end
		end;

		Connect = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(callbacks, callback)
			return {Disconnect = function(): ()
				const index = table.find(callbacks, callback)
				if index then
					table.remove(callbacks, index)
				end
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function(): ()
				const index = table.find(waiting, callback)
				if index then
					table.remove(waiting, index)
				end
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): (boolean, ...any)
			const co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					const index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			const returns = {coroutine.yield()}
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return table.unpack(returns)
		end;

		DisconnectAll = function(self: Event<...any>): ()
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" and coroutine.status(callback) == "suspended" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	return table.freeze(actions) :: Event<...any>
end

--- Creates and returns a `QueuedEvent`.
--- @param nameHint? -- The name of the `QueuedEvent` for debugging.
--- @param queueSize? -- The queue size of the `QueuedEvent`.
--- @return Event<...any> -- The new `QueuedEvent`.
function New.QueuedEvent(nameHint: string?, queueSize: number?): Event<...any>
	const queueSize = queueSize or QUEUED_EVENT_QUEUE_SIZE

	const callbacks: {Callback<...any>} = {}
	const waiting: {Callback<...any> | thread} = {}
	local queueCount = 0
	const queuedEventInvocations: {{any}} = {}

	const function resumeQueuedEventInvocations(self: Event<...any>): {any}?
		const _, firstInvocation = next(queuedEventInvocations)

		if next(callbacks) or next(waiting) then
			for _, invocation in queuedEventInvocations do
				self:Fire(table.unpack(invocation))
			end
		end

		table.clear(queuedEventInvocations)
		queueCount = 0

		return firstInvocation
	end

	const actions: Event<...any> = {
		Fire = function(self: Event<...any>, ...: any): ()
			if not next(callbacks) and not next(waiting) then
				if queueCount >= queueSize then
					task.spawn(error, `QueuedEvent invocation queue exhausted{if nameHint then ` for "{nameHint}"` else ""}; did you forget to connect to it?`, 0)
				end
				queueCount += 1
				table.insert(queuedEventInvocations, {...})
			else
				const currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in table.clone(callbacks) do
					task.spawn(callback, ...)
				end
				for _, callback in currentlyWaiting do
					if typeof(callback) == "thread" then
						if coroutine.status(callback) ~= "suspended" then continue end
						task.spawn(callback, true, ...)
					else
						task.spawn(callback, ...)
					end
				end
			end
		end;

		Connect = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(callbacks, callback)
			resumeQueuedEventInvocations(self)
			return {Disconnect = function(): ()
				const index = table.find(callbacks, callback)
				if index then
					table.remove(callbacks, index)
				end
			end}
		end;

		Once = function(self: Event<...any>, callback: Callback<...any>): Connection
			table.insert(waiting, callback)
			resumeQueuedEventInvocations(self)
			return {Disconnect = function(): ()
				const index = table.find(waiting, callback)
				if index then
					table.remove(waiting, index)
				end
			end}
		end;

		Wait = function(self: Event<...any>, timeout: number?): (boolean, ...any)
			const queuedInvocation = resumeQueuedEventInvocations(self)
			if queuedInvocation then
				return true, table.unpack(queuedInvocation)
			end
			const co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					const index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			const returns = {coroutine.yield()}
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return table.unpack(returns)
		end;

		DisconnectAll = function(self: Event<...any>): ()
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" and coroutine.status(callback) == "suspended" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	return table.freeze(actions) :: Event<...any>
end

--- Creates and returns a `TrackedVariable`.
--- @param variable -- The initial value of the `TrackedVariable`.
--- @return TrackedVariable<T> -- The new `TrackedVariable`.
function New.TrackedVariable<T>(variable: T): TrackedVariable<T>
	const callbacks: {Callback<T, T>} = {}
	const waiting: {Callback<T, T> | thread} = {}

	const actions: TrackedVariable<T> = {
		Get = function(self: TrackedVariable<T>): T
			return variable
		end;

		Set = function(self: TrackedVariable<T>, newValue: T): ()
			if variable ~= newValue then
				const oldValue = variable
				variable = newValue
				const currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in table.clone(callbacks) do
					task.spawn(callback, oldValue, newValue)
				end
				for _, callback in currentlyWaiting do
					if typeof(callback) == "thread" then
						if coroutine.status(callback) ~= "suspended" then continue end
						task.spawn(callback, true, oldValue, newValue)
					else
						task.spawn(callback, oldValue, newValue)
					end
				end
			end
		end;

		Connect = function(self: TrackedVariable<T>, callback: Callback<T, T>): Connection
			table.insert(callbacks, callback)
			return {Disconnect = function(): ()
				const index = table.find(callbacks, callback)
				if index then
					table.remove(callbacks, index)
				end
			end}
		end;

		Once = function(self: TrackedVariable<T>, callback: Callback<T, T>): Connection
			table.insert(waiting, callback)
			return {Disconnect = function(): ()
				const index = table.find(waiting, callback)
				if index then
					table.remove(waiting, index)
				end
			end}
		end;

		Wait = function(self: TrackedVariable<T>, timeout: number?): (boolean, T, T)
			const co = coroutine.running()
			table.insert(waiting, co)
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					const index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			const returns = {coroutine.yield()}
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return (table.unpack :: any)(returns)
		end;

		WaitFor = function(self: TrackedVariable<T>, value: T, timeout: number?): (boolean, T, T)
			const co = coroutine.running()
			local timeoutThread: thread?
			if timeout then
				timeoutThread = task.delay(timeout, function(): ()
					if coroutine.status(co) == "suspended" then
						task.spawn(co, false)
					end
				end)
			end
			local success: boolean, oldValue: T?, newValue: T?
			repeat
				success, oldValue, newValue = self:Wait()
			until not success or newValue == value
			if timeoutThread and coroutine.status(timeoutThread) == "suspended" then
				task.cancel(timeoutThread)
			end
			return success, oldValue, newValue
		end;

		DisconnectAll = function(self: TrackedVariable<T>): ()
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" and coroutine.status(callback) == "suspended" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	return table.freeze(actions) :: TrackedVariable<T>
end

--- Starts an `InstanceStream` and returns its UID and any newly created `Instances`.
--- @param players -- The list of `Players` to stream `Instances` to.
--- @param instances -- The list of `Instances` to stream.
--- @param exclusive? -- Whether or not to exclusively replicate the list of `Instances` by moving them into `PlayerGui`. If the first argument is an array of `Players`, the `Instances` are cloned.
--- @return string -- The UID of the `InstanceStream`.
--- @return {[Player]: Instance}? -- The containers which were created as a result of `exclusive?` = `true`.
--- @return {[Player]: {any}}? -- The `Instances` which were cloned as a result of `players` = `{Player}` and `exclusive?` = `true`.
--- @error InstanceStream cannot be created on the client -- Incorrect usage.
function New.ServerInstanceStream(players: Player | {Player}, instances: {Instance}, exclusive: boolean?): (string, {[Player]: Instance}?, {[Player]: {any}}?)
	if IS_CLIENT then error("InstanceStream cannot be created on the client", 0) end

	const uid = `{HttpService:GenerateGUID(false)}_{#instances}`
	const containers: {[Player]: Instance}? = if exclusive then {} else nil
	const clonedInstances: {[Player]: {any}}? = if exclusive and type(players) == "table" then {} else nil
	const ancestryListeners: {RBXScriptConnection} = {}

	for _, player in (if type(players) == "table" then players else {players}) :: {Player} do
		if not player.Parent then continue end

		const container = Instance.new("ScreenGui")
		container.Name = `__instanceStream_{uid}`
		container.Enabled = false
		container.ResetOnSpawn = false

		const remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.OnServerEvent:Connect(function(): ()
			if not exclusive then
				container:Destroy()
				for _, connection in ancestryListeners do
					connection:Disconnect()
				end
			end
		end)
		remoteEvent.Parent = container

		if containers then
			containers[player] = container
		end

		if clonedInstances then
			clonedInstances[player] = {}
		end

		for index, instance in instances do
			if clonedInstances then
				instance = instance:Clone()
				clonedInstances[player][index] = instance
			end
			const objectValue = Instance.new("ObjectValue")
			objectValue.Name = tostring(index)
			objectValue.Value = instance
			objectValue:SetAttribute("FullName", instance:GetFullName())
			New.Children(objectValue, if exclusive then {instance} else nil)
			objectValue.Parent = container

			table.insert(ancestryListeners, instance.AncestryChanged:Connect(function(): ()
				if not instance.Parent then
					objectValue:SetAttribute("Canceled", true)
				end
			end))
		end

		container.Parent = player.PlayerGui

		if not exclusive then
			task.delay(30, container.Destroy, container)
		end
	end

	return uid, containers, clonedInstances
end

--- Listens to an `InstanceStream` and returns activity `Events`.
--- @param uid -- The UID of the `InstanceStream`.
--- @return Event<...Instance?> -- The `Event` that fires when the `ClientInstanceStream` has received all `Instances`.
--- @return Event<Instance?> -- The `Event` that fires when an `Instance` is received.
--- @return Instance -- The container for the `InstanceStream`.
--- @error ClientInstanceStream cannot be created on the server -- Incorrect usage.
function New.ClientInstanceStream(uid: string): (Event<...Instance?>, Event<Instance?>, Instance)
	if IS_SERVER then error("ClientInstanceStream cannot be created on the server", 0) end

	const container = assert(localPlayer.PlayerGui:WaitForChild("__instanceStream_" .. uid, 30), `Cannot find InstanceStream with UID "{uid}"`) :: ScreenGui
	const remoteEvent = assert(container:WaitForChild("RemoteEvent", 30), `InstanceStream with UID "{uid}" missing RemoteEvent`) :: RemoteEvent
	const numInstances = assert(tonumber(uid:split("_")[2]))
	const instances: {Instance} = {}
	const failedInstances: {true} = {}
	local finished = false
	const finishedEvent = New.QueuedEvent("InstanceStream Finished Event") :: Event<...Instance?>
	const streamEvent = New.QueuedEvent("InstanceStream Stream Event", math.huge) :: Event<Instance?>

	const function checkFinished(): boolean
		if finished then return true end
		for index = 1, numInstances do
			if not instances[index] and not failedInstances[index] then
				return false
			end
		end
		finished = true
		finishedEvent:Fire(table.unpack(instances))
		finishedEvent:DisconnectAll()
		streamEvent:DisconnectAll()
		remoteEvent:FireServer()
		Print(`InstanceStream "{uid}" finished`)
		return true
	end

	container.Destroying:Once(function(): ()
		for _, child in container:GetChildren() do
			if child:IsA("ObjectValue") and not child.Value and not child:GetAttribute("Canceled") then
				child:SetAttribute("Canceled", true)
			end
		end
		finishedEvent:DisconnectAll()
		streamEvent:DisconnectAll()
	end)

	container.Parent = localPlayer

	Print(`InstanceStream "{uid}" starting`)

	for _, child in container:GetChildren() do
		if not child:IsA("ObjectValue") then continue end
		if child:GetAttribute("Canceled") then
			Warn(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
			failedInstances[tonumber(child.Name) :: number] = true
			streamEvent:Fire(nil)
			checkFinished()
		elseif child.Value then
			Print(`InstanceStream "{uid}" received "{child.Name}": {child.Value:GetFullName()}`)
			instances[tonumber(child.Name) :: number] = child.Value
			streamEvent:Fire(child.Value)
		else
			child:GetAttributeChangedSignal("Canceled"):Once(function(): ()
				Warn(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
				failedInstances[tonumber(child.Name) :: number] = true
				streamEvent:Fire(nil)
				checkFinished()
			end)
			child.Changed:Once(function(): ()
				assert(child.Value)
				Print(`InstanceStream "{uid}" received "{child.Name}": {child.Value:GetFullName()}`)
				instances[tonumber(child.Name) :: number] = child.Value
				streamEvent:Fire(child.Value)
				checkFinished()
			end)
		end
	end

	if not checkFinished() then
		container.ChildAdded:Connect(function(child: Instance): ()
			if not child:IsA("ObjectValue") then return end
			child:GetAttributeChangedSignal("Canceled"):Once(function(): ()
				Warn(`InstanceStream "{uid}" canceled "{child.Name}": {child:GetAttribute("FullName")}`)
				failedInstances[tonumber(child.Name) :: number] = true
				streamEvent:Fire(nil)
				checkFinished()
			end)
			child.Changed:Once(function(): ()
				assert(child.Value)
				Print(`InstanceStream "{uid}" received "{child.Name}": {child.Value:GetFullName()}`)
				instances[tonumber(child.Name) :: number] = child.Value
				streamEvent:Fire(child.Value)
				checkFinished()
			end)
		end)
	end

	return finishedEvent, streamEvent, container
end

--- Applies properties, attributes, tags, callbacks, and children to an Instance.
--- @param instance -- The Instance to apply to.
--- @param properties -- A table of properties to apply to the Instance.
function New.Properties<T>(instance: T & Instance, properties: Properties)
	for key, value in properties do
		if key == "Children" then
			for _, child in value do
				child.Parent = instance
			end
		elseif key == "Attributes" then
			for attributeName, attribute in value do
				instance:SetAttribute(attributeName, attribute)
			end
		elseif key == "Tags" then
			for _, tag in value do
				instance:AddTag(tag)
			end
		elseif typeof((instance :: any)[key]) == "RBXScriptSignal" then
			(instance :: any)[key]:Connect(value)
		else
			(instance :: any)[key] = value
		end
	end
end

--- Creates and returns a TrackedVariable.
--- @param variable -- The initial value of the TrackedVariable.
--- @return TrackedVariable -- The new TrackedVariable.
function New.Var(variable: any): TrackedVariable
	local callbacks: {Callback} = {}
	local waiting: {Callback | thread} = {}

	local actions: TrackedVariable = {
		Get = function(_): any
			return variable
		end;

		Set = function(_, value: any)
			if variable ~= value then
				variable = value
				for _, callback in callbacks do
					task.spawn(callback, value)
				end
				local currentlyWaiting = table.clone(waiting)
				table.clear(waiting)
				for _, callback in currentlyWaiting do
					task.spawn(callback, value)
				end
			end
		end;

		Connect = function(_, callback: Callback)
			table.insert(callbacks, callback)
			return {Disconnect = function()
				table.remove(callbacks, table.find(callbacks, callback))
			end}
		end;

		Once = function(_, callback: Callback)
			table.insert(waiting, callback)
			return {Disconnect = function()
				table.remove(waiting, table.find(waiting, callback))
			end}
		end;

		Wait = function(_, timeout: number?)
			local co = coroutine.running()
			table.insert(waiting, co)
			if timeout then
				task.delay(timeout, function()
					local index = table.find(waiting, co)
					if index then
						table.remove(waiting, index)
					end
					task.spawn(co)
				end)
			end
			return coroutine.yield()
		end;

		DisconnectAll = function(_)
			table.clear(callbacks)
			for _, callback in waiting do
				if type(callback) == "thread" then
					task.cancel(callback)
				end
			end
			table.clear(waiting)
		end;
	}

	table.freeze(actions)

	return actions
end

--- Creates and returns a new Instance.
--- @param className -- The ClassName for the Instance being created.
--- @param parent? -- The Parent for the Instance after creation.
--- @param name? -- The Name for the Instance.
--- @param properties? -- A table of properties to apply to the Instance.
--- @return Instance -- The new Instance.
--- @error Parent parameter used more than once -- Incorrect usage.
--- @error Name parameter used more than once -- Incorrect usage.
--- @error Properties parameter used more than once -- Incorrect usage.
function New.Instance(className: string, ...: (Instance | string | Properties)?): any
	local parent: Instance?, name: string?, properties: Properties?;
	for _, parameter in {...} do
		if typeof(parameter) == "Instance" then
			if parent then error("Parent parameter used more than once") end
			parent = parameter
		elseif type(parameter) == "string" or type(parameter) == "number" then
			if name then error("Name parameter used more than once") end
			name = tostring(parameter)
		elseif type(parameter) == "table" then
			if properties then error("Properties parameter used more than once") end
			properties = parameter
		end
	end

	local newInstance = Instance.new(className)

	if name then
		newInstance.Name = name
	end
	if properties then
		New.Properties(newInstance, properties)
	end
	if parent then
		newInstance.Parent = parent
	end

	return newInstance
end

--- Clones and returns an Instance.
--- @param instance -- The Instance to clone from.
--- @param parent? -- The Parent for the cloned Instance after creation.
--- @param name? -- The Name for the cloned Instance.
--- @param properties? -- A table of properties to apply to the cloned Instance.
--- @return Instance -- The cloned Instance.
--- @error Attempt to clone non-Instance -- Incorrect usage.
--- @error Parent parameter used more than once -- Incorrect usage.
--- @error Name parameter used more than once -- Incorrect usage.
--- @error Properties parameter used more than once -- Incorrect usage.
function New.Clone<T>(instance: T & Instance, ...: (Instance | string | Properties)?): T
	assert(typeof(instance) == "Instance", "Attempt to clone non-Instance")

	local parent: Instance?, name: string?, properties: Properties?;
	for _, parameter in {...} do
		if typeof(parameter) == "Instance" then
			if parent then error("Parent parameter used more than once") end
			parent = parameter
		elseif type(parameter) == "string" or type(parameter) == "number" then
			if name then error("Name parameter used more than once") end
			name = tostring(parameter)
		elseif type(parameter) == "table" then
			if properties then error("Properties parameter used more than once") end
			properties = parameter
		end
	end

	local newInstance = instance:Clone()

	if name then
		newInstance.Name = name
	end
	if properties then
		New.Properties(newInstance, properties)
	end
	if parent then
		newInstance.Parent = parent
	end

	return newInstance
end

function New.Clean(From: any, Find: string)
	if not From then return end
	if From:FindFirstChild(Find) then
		From[Find]:Destroy()
	end
end

function New.CleanAll(From: Instance, ...)
	if not From then return end
	local List = {...}
	for _, Object in pairs(From:GetChildren()) do
		for _, Name in pairs(List) do
			if Object.Name == Name then
				Object:Destroy()
				break
			end
		end
	end
end

function New.CleanAllDeep(From: Instance, ...)
	if not From then return end
	local List = {...}
	for _, Object in pairs(From:GetDescendants()) do
		for _, Name in pairs(List) do
			if Object.Name == Name then
				Object:Destroy()
				break
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return New