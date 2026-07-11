--!strict
-- Every RemoteEvent/RemoteFunction the Hardcore pack uses, defined once.
-- Server calls CreateAll() at startup; both sides call GetEvent/GetFunction.
-- Mirrors the existing Net.lua convention (own folder so pack remotes never
-- collide with the base pack's "Remotes" folder/names).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

type RemoteKind = "Event" | "Function"

-- Payload shapes (server -> client unless noted):
--   StateChanged(state: string, payload: {}) -- round manager state transitions
--   Tick(secondsRemaining: number) -- countdown ticks for the current state
--   QueueUpdate(count: number, names: {string}, minToStart: number)
--   RequestJoinQueue() -- client -> server, no payload
--   RequestLeaveQueue() -- client -> server, no payload
--   GameUpdate(data: {}) -- per-tick HUD payload: timer/playersLeft/yourScore/...
--   YouWereEliminated() -- targeted to one client, enters spectator overlay
--   ResultsShow(results: { {Name: string, Placement: number, Score: number} })
--   GetLeaderboardSnapshot() -> {TopN: {}, Self: {}} -- RemoteFunction, client -> server
local REMOTE_DEFS: { { Name: string, Kind: RemoteKind } } = {
	{ Name = "StateChanged", Kind = "Event" },
	{ Name = "Tick", Kind = "Event" },
	{ Name = "QueueUpdate", Kind = "Event" },
	{ Name = "RequestJoinQueue", Kind = "Event" },
	{ Name = "RequestLeaveQueue", Kind = "Event" },
	{ Name = "GameUpdate", Kind = "Event" },
	{ Name = "YouWereEliminated", Kind = "Event" },
	{ Name = "ResultsShow", Kind = "Event" },
	{ Name = "GetLeaderboardSnapshot", Kind = "Function" },
}

local FOLDER_NAME = "HardcoreRemotes"

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		return existing :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

function Remotes.CreateAll(): Folder
	local folder = getFolder()
	for _, def in REMOTE_DEFS do
		if not folder:FindFirstChild(def.Name) then
			local instance: Instance = if def.Kind == "Function"
				then Instance.new("RemoteFunction")
				else Instance.new("RemoteEvent")
			instance.Name = def.Name
			instance.Parent = folder
		end
	end
	return folder
end

function Remotes.GetEvent(name: string): RemoteEvent
	local folder = getFolder()
	local remote = folder:WaitForChild(name, 10)
	assert(remote ~= nil, `HardcoreRemotes: event "{name}" was not found`)
	return remote :: RemoteEvent
end

function Remotes.GetFunction(name: string): RemoteFunction
	local folder = getFolder()
	local remote = folder:WaitForChild(name, 10)
	assert(remote ~= nil, `HardcoreRemotes: function "{name}" was not found`)
	return remote :: RemoteFunction
end

return Remotes
