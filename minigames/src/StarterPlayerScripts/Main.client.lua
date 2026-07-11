--!strict
-- Client entry point: wires server state broadcasts to the HUD, intermission, and
-- winner screens, and keeps the coin count in sync with the leaderstats value.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Net"))

local Modules = script.Parent:WaitForChild("Modules")
local HUD = require(Modules:WaitForChild("HUD"))
local IntermissionScreen = require(Modules:WaitForChild("IntermissionScreen"))
local WinnerScreen = require(Modules:WaitForChild("WinnerScreen"))
local SoundPlayer = require(Modules:WaitForChild("SoundPlayer"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local hud = HUD.new(playerGui)
local intermission = IntermissionScreen.new(playerGui)
local winnerScreen = WinnerScreen.new(playerGui)

local stateChanged = Net.GetRemote("StateChanged")
local tick = Net.GetRemote("Tick")

local currentState = "Intermission"
local currentGameName = ""

stateChanged.OnClientEvent:Connect(function(state: string, data: { [string]: any })
	currentState = state

	if state == "WaitingForPlayers" then
		intermission:Show("Waiting for players...")
		winnerScreen:Hide()
		hud:SetVisible(false)
	elseif state == "Intermission" then
		currentGameName = data.GameName or ""
		intermission:Show(`Next up: {currentGameName}`)
		winnerScreen:Hide()
		hud:SetVisible(false)
		SoundPlayer.Play("Countdown")
	elseif state == "Round" then
		currentGameName = data.GameName or ""
		intermission:Hide()
		winnerScreen:Hide()
		hud:SetVisible(true)
		hud:SetGameName(currentGameName)
		SoundPlayer.Play("RoundStart")
	elseif state == "Results" then
		hud:SetVisible(false)
		intermission:Hide()
		winnerScreen:Show(currentGameName, data.WinnerNames or {})
		SoundPlayer.Play("Victory")
	end
end)

tick.OnClientEvent:Connect(function(timeLeft: number)
	if currentState == "Round" then
		hud:SetTime(timeLeft)
	elseif currentState == "Intermission" or currentState == "WaitingForPlayers" then
		intermission:SetCountdown(timeLeft)
	end
end)

local function watchCoins()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Coins") :: IntValue
	hud:SetCoins(coins.Value)
	coins:GetPropertyChangedSignal("Value"):Connect(function()
		hud:SetCoins(coins.Value)
	end)
end

task.spawn(watchCoins)
