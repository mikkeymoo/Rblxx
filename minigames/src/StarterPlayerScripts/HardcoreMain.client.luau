--!strict
-- Client entry point for the Hardcore Minigame Pack. Wires server state
-- broadcasts to UI; the server drives every value, this script only renders
-- and forwards clicks back as remote calls. Sibling to Main.client.lua (the
-- base pack's own entry point) — the two run side by side untouched.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Hardcore:WaitForChild("Remotes"))

local Modules = script.Parent:WaitForChild("HardcoreModules")
local QueueWidget = require(Modules:WaitForChild("QueueWidget"))
local IntermissionUI = require(Modules:WaitForChild("IntermissionUI"))
local GameHUD = require(Modules:WaitForChild("GameHUD"))
local EliminationOverlay = require(Modules:WaitForChild("EliminationOverlay"))
local ResultsUI = require(Modules:WaitForChild("ResultsUI"))
local LeaderboardUI = require(Modules:WaitForChild("LeaderboardUI"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local queueWidget = QueueWidget.new(playerGui)
local intermissionUI = IntermissionUI.new(playerGui)
local gameHUD = GameHUD.new(playerGui)
local eliminationOverlay = EliminationOverlay.new(playerGui)
local resultsUI = ResultsUI.new(playerGui)
local leaderboardUI = LeaderboardUI.new(playerGui)

local stateChanged = Remotes.GetEvent("StateChanged")
local tick = Remotes.GetEvent("Tick")
local queueUpdate = Remotes.GetEvent("QueueUpdate")
local requestJoinQueue = Remotes.GetEvent("RequestJoinQueue")
local requestLeaveQueue = Remotes.GetEvent("RequestLeaveQueue")
local gameUpdate = Remotes.GetEvent("GameUpdate")
local youWereEliminated = Remotes.GetEvent("YouWereEliminated")
local resultsShow = Remotes.GetEvent("ResultsShow")
local getLeaderboardSnapshot = Remotes.GetFunction("GetLeaderboardSnapshot")

local currentState = "WaitingForPlayers"
local currentGameName = ""
local amQueued = false
local amParticipant = false
local countdownThread: thread? = nil

local function stopLocalCountdown()
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
end

-- The round itself has no server Tick broadcast (ticking every second for a
-- long InProgress phase would be wasted traffic); the client instead counts
-- down locally from the duration the server already announced. Purely
-- cosmetic — every elimination/score decision still comes from the server.
local function startLocalCountdown(duration: number)
	stopLocalCountdown()
	countdownThread = task.spawn(function()
		local remaining = duration
		while remaining > 0 do
			gameHUD:SetTime(remaining)
			task.wait(1)
			remaining -= 1
		end
	end)
end

queueWidget.JoinClicked:Connect(function()
	requestJoinQueue:FireServer()
end)

queueWidget.LeaveClicked:Connect(function()
	requestLeaveQueue:FireServer()
end)

queueWidget.LeaderboardClicked:Connect(function()
	if leaderboardUI:IsVisible() then
		leaderboardUI:Toggle()
		return
	end
	task.spawn(function()
		local ok, snapshot = pcall(function()
			return getLeaderboardSnapshot:InvokeServer()
		end)
		if ok and snapshot then
			leaderboardUI:SetData(
				snapshot.TopN or {},
				snapshot.Self or { Wins = 0, Points = 0, BestPlacement = 0, GamesPlayed = 0 }
			)
		end
		leaderboardUI:Show()
	end)
end)

queueUpdate.OnClientEvent:Connect(function(count: number, names: { string }, minToStart: number)
	amQueued = table.find(names, player.Name) ~= nil
	queueWidget:SetQueue(count, minToStart, amQueued)
end)

stateChanged.OnClientEvent:Connect(function(state: string, data: { [string]: any })
	currentState = state
	stopLocalCountdown()

	if state == "WaitingForPlayers" then
		intermissionUI:Hide()
		gameHUD:SetVisible(false)
		resultsUI:Hide()
		eliminationOverlay:Hide()
	elseif state == "Intermission" then
		currentGameName = data.GameName or ""
		if amQueued then
			intermissionUI:Show(`Next up: {currentGameName}`)
		end
		gameHUD:SetVisible(false)
		resultsUI:Hide()
		eliminationOverlay:Hide()
	elseif state == "Loading" then
		local roundPlayers = (data.Players :: { string }?) or {}
		amParticipant = table.find(roundPlayers, player.Name) ~= nil
		if amParticipant then
			intermissionUI:Show(`Loading {currentGameName}...`)
		else
			intermissionUI:Hide()
		end
	elseif state == "InProgress" then
		local roundPlayers = (data.Players :: { string }?) or {}
		amParticipant = table.find(roundPlayers, player.Name) ~= nil
		currentGameName = data.GameName or currentGameName
		intermissionUI:Hide()
		eliminationOverlay:Hide()
		if amParticipant then
			gameHUD:SetVisible(true)
			gameHUD:SetGameName(currentGameName)
			local duration = data.Duration
			if type(duration) == "number" then
				startLocalCountdown(duration)
			end
		end
	elseif state == "Results" then
		gameHUD:SetVisible(false)
		intermissionUI:Hide()
	end
end)

tick.OnClientEvent:Connect(function(secondsLeft: number)
	if currentState == "Intermission" or currentState == "Loading" or currentState == "WaitingForPlayers" then
		if amQueued or amParticipant then
			intermissionUI:SetCountdown(secondsLeft)
		end
	end
end)

gameUpdate.OnClientEvent:Connect(function(data: { [string]: any })
	if amParticipant then
		gameHUD:ApplyUpdate(data)
	end
end)

youWereEliminated.OnClientEvent:Connect(function()
	eliminationOverlay:Show()
end)

resultsShow.OnClientEvent:Connect(function(results: { ResultsUI.ResultEntry })
	resultsUI:Show(currentGameName, results)
end)
