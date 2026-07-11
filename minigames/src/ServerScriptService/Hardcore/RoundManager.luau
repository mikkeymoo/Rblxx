--!strict
-- Server-authoritative round state machine for the Hardcore pack:
-- WaitingForPlayers -> Intermission -> Loading -> InProgress -> Results -> loop.
-- Picks the next valid minigame from the registry by queue size/mode, drives
-- it through the common interface, awards points, persists to the
-- leaderboard, and guarantees per-round cleanup via a fresh Trove each lap.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage.Hardcore:WaitForChild("Remotes"))
local TroveModule = require(ReplicatedStorage.Hardcore:WaitForChild("Trove"))
local Signal = require(ReplicatedStorage.Hardcore:WaitForChild("Signal"))
local Types = require(ReplicatedStorage.Hardcore:WaitForChild("Types"))

local Registry = require(script.Parent:WaitForChild("MinigameRegistry"))
local Matchmaking = require(script.Parent:WaitForChild("Matchmaking"))
local Leaderboard = require(script.Parent:WaitForChild("Leaderboard"))

local RoundManager = {}

export type RoundState = "WaitingForPlayers" | "Intermission" | "Loading" | "InProgress" | "Results"

local ARENA_ROOT_NAME = "HardcoreArenas"
local timesPlayed: { [string]: number } = {}

local function getArenaRoot(): Folder
	local existing = Workspace:FindFirstChild(ARENA_ROOT_NAME)
	if existing then
		return existing :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name = ARENA_ROOT_NAME
	folder.Parent = Workspace
	return folder
end

local function broadcastState(state: RoundState, payload: { [string]: any })
	Remotes.GetEvent("StateChanged"):FireAllClients(state, payload)
end

local function countdown(seconds: number)
	local tickRemote = Remotes.GetEvent("Tick")
	for i = seconds, 1, -1 do
		tickRemote:FireAllClients(i)
		task.wait(1)
	end
end

local function playerNames(players: { Player }): { string }
	local names = {}
	for _, player in players do
		table.insert(names, player.Name)
	end
	return names
end

local function pickGame(playerCount: number): Registry.RegisteredGame?
	local valid = Registry.GetValidGames(playerCount, "FFA")
	if #valid == 0 then
		return nil
	end
	return valid[math.random(1, #valid)]
end

local function awardPoints(results: { Types.PlayerResult })
	for _, result in results do
		if result.Player.Parent then
			local points = Config.PointsByPlacement[result.Placement] or Config.ParticipationPoints
			Leaderboard.RecordRoundResult(result.Player, result.Placement, points, result.Placement == 1)
		end
	end
end

function RoundManager.Run()
	Remotes.CreateAll()
	local arenaRoot = getArenaRoot()

	while true do
		broadcastState("WaitingForPlayers", {})
		while Matchmaking.GetQueueCount() < Config.MinPlayersToStart do
			Matchmaking.BroadcastQueue()
			task.wait(Config.WaitingBroadcastInterval)
		end

		local picked = pickGame(Matchmaking.GetQueueCount())
		if not picked then
			-- Queue is non-empty but no registered game fits it (e.g. every
			-- game's MaxPlayers is smaller than the queue); wait for room.
			task.wait(Config.WaitingBroadcastInterval)
			continue
		end

		broadcastState("Intermission", { GameName = picked.Metadata.Name })
		countdown(Config.IntermissionTime)

		local dequeueCount = math.min(Matchmaking.GetQueueCount(), picked.Metadata.MaxPlayers)
		if dequeueCount < picked.Metadata.MinPlayers then
			continue -- players left the queue during intermission; try again
		end
		local participants = Matchmaking.Dequeue(dequeueCount)

		broadcastState("Loading", { GameName = picked.Metadata.Name, Players = playerNames(participants) })

		local roundTrove = TroveModule.new()
		local arenaContainer = picked.BuildMap(arenaRoot)
		roundTrove:Add(arenaContainer)

		timesPlayed[picked.Metadata.Name] = (timesPlayed[picked.Metadata.Name] or 0) + 1

		local context: Types.MinigameContext = {
			Participants = participants,
			Arena = arenaContainer,
			Config = Config,
			Cleanup = roundTrove,
			RoundIndex = timesPlayed[picked.Metadata.Name] :: number,
			Mode = "FFA",
		}

		local instance = picked.Module.new(context)

		-- A player disconnecting mid-round funnels through the same
		-- elimination path as an in-game death so alive-counts stay correct.
		roundTrove:Connect(Players.PlayerRemoving, function(player: Player)
			if table.find(participants, player) then
				instance:OnPlayerEliminated(player)
			end
		end)

		countdown(Config.LoadingTime)

		broadcastState("InProgress", {
			GameName = picked.Metadata.Name,
			PlayerCount = #participants,
			Players = playerNames(participants),
			Duration = picked.Metadata.RoundDurationCap,
		})

		local done = Signal.new()
		local completedConnection = instance.Completed:Once(function()
			done:Fire()
		end)
		local capThread = task.delay(picked.Metadata.RoundDurationCap, function()
			done:Fire()
		end)

		instance:Start()
		done:Wait()
		done:Destroy()
		completedConnection:Disconnect()
		task.cancel(capThread)

		instance:Stop()
		local results = instance:GetResults()

		broadcastState("Results", { GameName = picked.Metadata.Name })

		local resultsPayload = {}
		for _, result in results do
			if result.Player.Parent then
				table.insert(resultsPayload, {
					Name = result.Player.Name,
					Placement = result.Placement,
					Score = result.Score,
				})
			end
		end
		Remotes.GetEvent("ResultsShow"):FireAllClients(resultsPayload)
		awardPoints(results)

		countdown(Config.ResultsTime)

		roundTrove:Clean()
		Matchmaking.ReturnFromRound(participants)
	end
end

return RoundManager
