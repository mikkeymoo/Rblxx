--!strict
-- Shared tunable values for the round loop, lobby, minigames, and client presentation.

export type Config = {
	IntermissionTime: number,
	RoundTime: number,
	ResultsTime: number,
	MinPlayers: number,

	LobbyRadius: number,
	SpawnPadCount: number,

	CoinsPerWin: number,
	CoinsParticipation: number,

	Spleef: {
		Center: Vector3,
		ArenaRadius: number,
		TileSize: number,
		TileHeight: number,
		TileGap: number,
		FallDelay: number,
	},

	ColorRush: {
		Center: Vector3,
		GridSize: number,
		PadSize: number,
		InitialCountdown: number,
		MinCountdown: number,
		CountdownDecrement: number,
		FallDelay: number,
	},

	LavaRise: {
		Center: Vector3,
		TowerHeight: number,
		TowerRadius: number,
		PlatformSpacing: number,
		LavaStartHeight: number,
		LavaRiseSpeed: number,
		LavaRiseStartDelay: number,
	},

	Sounds: { [string]: string },
}

local Config: Config = {
	IntermissionTime = 15,
	RoundTime = 60,
	ResultsTime = 5,
	MinPlayers = 1,

	LobbyRadius = 40,
	SpawnPadCount = 8,

	CoinsPerWin = 50,
	CoinsParticipation = 5,

	Spleef = {
		Center = Vector3.new(300, 50, 0),
		ArenaRadius = 40,
		TileSize = 6,
		TileHeight = 1,
		TileGap = 0.5,
		FallDelay = 0.75,
	},

	ColorRush = {
		Center = Vector3.new(0, 50, 300),
		GridSize = 6,
		PadSize = 8,
		InitialCountdown = 5,
		MinCountdown = 2,
		CountdownDecrement = 0.5,
		FallDelay = 1.25,
	},

	LavaRise = {
		Center = Vector3.new(-300, 5, 0),
		TowerHeight = 120,
		TowerRadius = 24,
		PlatformSpacing = 10,
		LavaStartHeight = 0,
		LavaRiseSpeed = 1.4,
		LavaRiseStartDelay = 8,
	},

	-- rbxasset:// paths ship inside the Roblox client itself, no asset download required.
	Sounds = {
		RoundStart = "rbxasset://sounds/bell.wav",
		RoundEnd = "rbxasset://sounds/bell.wav",
		Countdown = "rbxasset://sounds/electronicpingshort.wav",
		Victory = "rbxasset://sounds/bell.wav",
		Eliminate = "rbxasset://sounds/impact_water.mp3",
	},
}

return Config
