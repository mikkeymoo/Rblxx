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

	ParkourRace: {
		Center: Vector3,
		SegmentCount: number,
		SegmentSpacing: number,
		PlatformSize: Vector3,
		FinishPlatformSize: Vector3,
		MovingEvery: number,
		MovingTravel: number,
		MovingDuration: number,
		FallMargin: number,
	},

	SimonSays: {
		Center: Vector3,
		PadSize: number,
		PadGap: number,
		StartLength: number,
		FlashTime: number,
		GapTime: number,
		StepTimeout: number,
		TouchCooldown: number,
		RoundPause: number,
	},

	InfectionTag: {
		Center: Vector3,
		ArenaRadius: number,
		WallHeight: number,
		PillarCount: number,
		PillarRadius: number,
		PillarHeight: number,
		TagRadius: number,
		InfectedSpeed: number,
		SurvivorSpeed: number,
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

	ParkourRace = {
		Center = Vector3.new(600, 50, 0),
		SegmentCount = 14,
		SegmentSpacing = 10,
		PlatformSize = Vector3.new(6, 1, 6),
		FinishPlatformSize = Vector3.new(12, 1, 12),
		MovingEvery = 3,
		MovingTravel = 7,
		MovingDuration = 1.6,
		FallMargin = 16,
	},

	SimonSays = {
		Center = Vector3.new(0, 50, 600),
		PadSize = 10,
		PadGap = 2,
		StartLength = 3,
		FlashTime = 0.6,
		GapTime = 0.35,
		StepTimeout = 2.5,
		TouchCooldown = 0.3,
		RoundPause = 1.25,
	},

	InfectionTag = {
		Center = Vector3.new(-600, 5, 0),
		ArenaRadius = 45,
		WallHeight = 12,
		PillarCount = 6,
		PillarRadius = 4,
		PillarHeight = 14,
		TagRadius = 6,
		InfectedSpeed = 20,
		SurvivorSpeed = 16,
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
