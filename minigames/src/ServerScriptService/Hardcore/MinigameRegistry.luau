--!strict
-- Registers the three Hardcore minigames against the common interface and
-- their map builders. RoundManager only ever talks to this module, never to
-- an individual minigame require directly, so adding a fourth game means
-- adding one entry here (see README "Adding a fourth game").
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Hardcore:WaitForChild("Types"))

local MinigamesFolder = script.Parent:WaitForChild("Minigames")
local MapBuildersFolder = script.Parent:WaitForChild("MapBuilders")

local CollapseProtocol = require(MinigamesFolder:WaitForChild("CollapseProtocol"))
local SignalJammer = require(MinigamesFolder:WaitForChild("SignalJammer"))
local FreefallGauntlet = require(MinigamesFolder:WaitForChild("FreefallGauntlet"))

local CollapseProtocolMap = require(MapBuildersFolder:WaitForChild("CollapseProtocolMap"))
local SignalJammerMap = require(MapBuildersFolder:WaitForChild("SignalJammerMap"))
local FreefallGauntletMap = require(MapBuildersFolder:WaitForChild("FreefallGauntletMap"))

export type RegisteredGame = {
	Metadata: Types.MinigameMetadata,
	Module: Types.MinigameClass,
	BuildMap: (parent: Instance) -> Folder,
}

local GAMES: { RegisteredGame } = {
	{ Metadata = CollapseProtocol.Metadata, Module = CollapseProtocol :: any, BuildMap = CollapseProtocolMap.Build },
	{ Metadata = SignalJammer.Metadata, Module = SignalJammer :: any, BuildMap = SignalJammerMap.Build },
	{ Metadata = FreefallGauntlet.Metadata, Module = FreefallGauntlet :: any, BuildMap = FreefallGauntletMap.Build },
}

local Registry = {}

function Registry.GetAll(): { RegisteredGame }
	return GAMES
end

-- Games a round is allowed to pick given the current queue size and mode.
function Registry.GetValidGames(playerCount: number, mode: Types.LobbyMode): { RegisteredGame }
	local valid: { RegisteredGame } = {}
	for _, game in GAMES do
		local meta = game.Metadata
		local countOk = playerCount >= meta.MinPlayers and playerCount <= meta.MaxPlayers
		local modeOk = mode == "FFA" or meta.SupportsTeams
		if countOk and modeOk then
			table.insert(valid, game)
		end
	end
	return valid
end

return Registry
