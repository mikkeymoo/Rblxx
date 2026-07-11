--!strict
-- Entry point for the Hardcore Minigame Pack: wires remotes, leaderboard
-- persistence, the queue kiosk, and matchmaking, then starts the round loop.
-- Sibling to Main.server.lua (the base pack's own entry point) — this file
-- only touches its own Hardcore/ namespace, so the base pack is untouched.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Hardcore:WaitForChild("Remotes"))

local Hardcore = ServerScriptService:WaitForChild("Hardcore")
local Leaderboard = require(Hardcore:WaitForChild("Leaderboard"))
local Matchmaking = require(Hardcore:WaitForChild("Matchmaking"))
local HardcoreLobby = require(Hardcore:WaitForChild("HardcoreLobby"))
local RoundManager = require(Hardcore:WaitForChild("RoundManager"))

Remotes.CreateAll()

Players.PlayerAdded:Connect(function(player)
	Leaderboard.Init(player)
end)

for _, player in Players:GetPlayers() do
	Leaderboard.Init(player)
end

Leaderboard.BindRemote()
Matchmaking.Init()
HardcoreLobby.Build()

RoundManager.Run()
