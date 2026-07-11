--!strict
-- Creates/locates the RemoteEvents used to drive client presentation. The server calls
-- CreateRemotes() once at startup; both server and client call GetRemote() to fetch one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local REMOTE_NAMES = { "StateChanged", "Tick" }

local function getRemotesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		return existing :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	return folder
end

function Net.CreateRemotes(): Folder
	local folder = getRemotesFolder()
	for _, name in REMOTE_NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	return folder
end

function Net.GetRemote(name: string): RemoteEvent
	local folder = getRemotesFolder()
	local remote = folder:WaitForChild(name, 10)
	assert(remote ~= nil, `Remote "{name}" was not found in ReplicatedStorage.Remotes`)
	return remote :: RemoteEvent
end

return Net
