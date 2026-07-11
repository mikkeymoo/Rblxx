--!strict
-- Server-authoritative round loop: Intermission -> random minigame -> Round -> Results -> repeat.
-- Requires Config.MinPlayers (default 1) so a solo player still cycles through for testing.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Net"))
local LobbyBuilder = require(script.Parent:WaitForChild("LobbyBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local MinigameUtils = require(script.Parent:WaitForChild("MinigameUtils"))

local Minigames = script.Parent:WaitForChild("Minigames")

export type MinigameModule = {
	Init: ({ Player }) -> (),
	Start: () -> (),
	Cleanup: () -> (),
	GetWinners: (boolean?) -> { Player },
}

local GAMES: { { Name: string, Module: MinigameModule } } = {
	{ Name = "Spleef", Module = require(Minigames:WaitForChild("Spleef")) :: MinigameModule },
	{ Name = "Color Rush", Module = require(Minigames:WaitForChild("ColorRush")) :: MinigameModule },
	{ Name = "Lava Rise", Module = require(Minigames:WaitForChild("LavaRise")) :: MinigameModule },
	{ Name = "Parkour Race", Module = require(Minigames:WaitForChild("ParkourRace")) :: MinigameModule },
	{ Name = "Simon Says", Module = require(Minigames:WaitForChild("SimonSays")) :: MinigameModule },
	{ Name = "Infection Tag", Module = require(Minigames:WaitForChild("InfectionTag")) :: MinigameModule },
}

local GameManager = {}

local function waitForPlayers(stateChanged: RemoteEvent)
	while #Players:GetPlayers() < Config.MinPlayers do
		stateChanged:FireAllClients("WaitingForPlayers", {})
		task.wait(2)
	end
end

local function countdown(seconds: number, tick: RemoteEvent)
	for i = seconds, 1, -1 do
		tick:FireAllClients(i)
		task.wait(1)
	end
end

local function teleportToLobby(players: { Player })
	for _, player in players do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
				humanoid.JumpHeight = 7.2
			end
		end
	end
	MinigameUtils.TeleportPlayersInCircle(players, Vector3.new(0, 0, 0), Config.LobbyRadius * 0.6, 5)
end

function GameManager.Run()
	LobbyBuilder.Build()
	Net.CreateRemotes()

	local stateChanged = Net.GetRemote("StateChanged")
	local tick = Net.GetRemote("Tick")

	while true do
		waitForPlayers(stateChanged)

		local pick = GAMES[math.random(1, #GAMES)]

		stateChanged:FireAllClients("Intermission", { GameName = pick.Name })
		countdown(Config.IntermissionTime, tick)

		local participants = Players:GetPlayers()
		if #participants < Config.MinPlayers then
			continue
		end

		pick.Module.Init(participants)
		stateChanged:FireAllClients("Round", { GameName = pick.Name })
		pick.Module.Start()

		local winners: { Player } = {}
		for i = Config.RoundTime, 1, -1 do
			tick:FireAllClients(i)
			task.wait(1)
			local roundWinners = pick.Module.GetWinners(false)
			if roundWinners and #roundWinners > 0 then
				winners = roundWinners
				break
			end
		end
		if #winners == 0 then
			winners = pick.Module.GetWinners(true)
		end

		pick.Module.Cleanup()

		local winnerNames: { string } = {}
		for _, player in winners do
			if player.Parent then
				PlayerData.AddCoins(player, Config.CoinsPerWin)
				table.insert(winnerNames, player.Name)
			end
		end
		for _, player in participants do
			if player.Parent and not table.find(winners, player) then
				PlayerData.AddCoins(player, Config.CoinsParticipation)
			end
		end

		stateChanged:FireAllClients("Results", { GameName = pick.Name, WinnerNames = winnerNames })
		countdown(Config.ResultsTime, tick)

		teleportToLobby(participants)
	end
end

return GameManager
