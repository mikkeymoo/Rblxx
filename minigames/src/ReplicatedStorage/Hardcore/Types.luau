--!strict
-- Shared type contracts for the Hardcore minigame pack. RoundManager and
-- every minigame module require this so the common interface can't drift.

local TroveModule = require(script.Parent:WaitForChild("Trove"))
local SignalModule = require(script.Parent:WaitForChild("Signal"))

export type Trove = TroveModule.Trove
export type Signal = SignalModule.Signal

export type LobbyMode = "FFA" | "Small" | "BattleRoyale" | "Teams"

export type PlayerResult = {
	Player: Player,
	Placement: number,
	Score: number,
}

-- Declared once by each minigame module (outside .new) so RoundManager can
-- filter valid games for the current player count/mode before starting one.
export type MinigameMetadata = {
	Name: string,
	MinPlayers: number,
	MaxPlayers: number,
	SupportsTeams: boolean,
	RoundDurationCap: number,
}

-- Handed to `.new()`. RoundIndex is how many times this exact game has been
-- picked so far this server session (drives light cross-match escalation);
-- within-round escalation is left to each game's own elapsed-time curve.
export type MinigameContext = {
	Participants: { Player },
	Arena: Folder,
	Config: any,
	Cleanup: Trove,
	RoundIndex: number,
	Mode: LobbyMode,
}

-- The uniform contract every minigame module returns. `Completed` fires
-- (no args) the moment a winner/placement order is decided, so RoundManager
-- can react to a signal instead of polling GetResults() every tick.
export type Minigame = {
	Completed: Signal,
	Start: (self: Minigame) -> (),
	Stop: (self: Minigame) -> (),
	OnPlayerEliminated: (self: Minigame, player: Player) -> (),
	GetResults: (self: Minigame) -> { PlayerResult },
}

export type MinigameClass = {
	Metadata: MinigameMetadata,
	new: (context: MinigameContext) -> Minigame,
}

return {}
