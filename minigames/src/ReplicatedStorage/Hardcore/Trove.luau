--!strict
-- Minimal cleanup-tracking utility (Trove/Maid pattern). Self-authored small
-- utility so every round and every minigame has one place to register
-- connections/instances/threads and guarantee they are torn down together.
-- No third-party dependency: this repo has no Wally/Rojo toolchain available
-- in the build environment to resolve one, so a small in-repo module avoids
-- shipping an unresolved package.

export type Trove = {
	Add: <T>(self: Trove, object: T, cleanupMethod: string?) -> T,
	Connect: (self: Trove, signal: RBXScriptSignal, fn: (...any) -> ()) -> RBXScriptConnection,
	AddThread: (self: Trove, thread: thread) -> thread,
	Clean: (self: Trove) -> (),
	Destroy: (self: Trove) -> (),
	Extend: (self: Trove) -> Trove,
}

type Entry = {
	Object: any,
	CleanupMethod: string?,
}

local Trove = {}
Trove.__index = Trove

local function cleanupEntry(entry: Entry)
	local object = entry.Object
	local method = entry.CleanupMethod

	if method then
		local fn = (object :: any)[method]
		if fn then
			fn(object)
		end
		return
	end

	if typeof(object) == "RBXScriptConnection" then
		object:Disconnect()
	elseif typeof(object) == "Instance" then
		object:Destroy()
	elseif typeof(object) == "thread" then
		task.cancel(object)
	elseif typeof(object) == "table" and object.Destroy then
		object:Destroy()
	elseif typeof(object) == "function" then
		object()
	end
end

function Trove.new(): Trove
	local self = setmetatable({
		_entries = {} :: { Entry },
	}, Trove)
	return (self :: any) :: Trove
end

function Trove:Add<T>(object: T, cleanupMethod: string?): T
	table.insert((self :: any)._entries, { Object = object, CleanupMethod = cleanupMethod })
	return object
end

function Trove:Connect(signal: RBXScriptSignal, fn: (...any) -> ()): RBXScriptConnection
	local connection = signal:Connect(fn)
	self:Add(connection)
	return connection
end

function Trove:AddThread(thread: thread): thread
	self:Add(thread)
	return thread
end

function Trove:Extend(): Trove
	local child = Trove.new()
	self:Add(child)
	return child
end

function Trove:Clean()
	local entries = (self :: any)._entries
	(self :: any)._entries = {}
	for i = #entries, 1, -1 do
		local ok, err = pcall(cleanupEntry, entries[i])
		if not ok then
			warn("[Trove] cleanup error:", err)
		end
	end
end

function Trove:Destroy()
	self:Clean()
end

return Trove
