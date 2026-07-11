--!strict
-- Single source of truth for every tunable in the Hardcore pack: round/
-- intermission timings, per-game escalation curves, point values, arena
-- dimensions, and matchmaking/leaderboard settings. Difficulty lives here,
-- not scattered through minigame logic.

export type EscalationCurve = {
	Start: number,
	Finish: number,
	Min: number?,
	Max: number?,
}

export type CollapseProtocolConfig = {
	Center: Vector3,
	RingCount: number,
	HexSize: number,
	HexHeight: number,
	HexGap: number,
	KillY: number,
	CrumbleDelay: EscalationCurve,
	RegrowDelaySeconds: number,
	RegrowDisabledAfterFraction: number,
	QuakeInterval: EscalationCurve,
	QuakeClusterSize: number,
	QuakeWarningTime: number,
}

export type SignalJammerConfig = {
	Center: Vector3,
	ArenaRadius: number,
	CapturePointRadius: number,
	CapturePointSpeed: number,
	CaptureScorePerSecond: number,
	PulseTelegraphTime: EscalationCurve,
	PulseInterval: EscalationCurve,
	PulseRadius: number,
	PulseActiveTime: number,
	MultiPulseAfterFraction: number,
}

export type FreefallGauntletConfig = {
	TopCenter: Vector3,
	KillY: number,
	RingCount: number,
	RingSpacing: number,
	RingRadius: number,
	RingThickness: number,
	GapSize: EscalationCurve,
	RotationSpeed: EscalationCurve,
	WindGustAfterFraction: number,
	WindGustInterval: number,
	WindGustForce: number,
}

export type PointsTable = { number }

export type Config = {
	IntermissionTime: number,
	LoadingTime: number,
	ResultsTime: number,
	WaitingBroadcastInterval: number,
	MinPlayersToStart: number,

	PointsByPlacement: PointsTable,
	ParticipationPoints: number,

	QueueKioskPosition: Vector3,
	QueueAreaRadius: number,

	LeaderboardDataStoreName: string,
	LeaderboardTopN: number,
	LeaderboardSaveRetries: number,
	LeaderboardSaveRetryDelay: number,
	LeaderboardRequestBudgetPerMinute: number,

	CollapseProtocol: CollapseProtocolConfig,
	SignalJammer: SignalJammerConfig,
	FreefallGauntlet: FreefallGauntletConfig,
}

local Config: Config = {
	IntermissionTime = 10,
	LoadingTime = 3,
	ResultsTime = 8,
	WaitingBroadcastInterval = 2,
	MinPlayersToStart = 2,

	PointsByPlacement = { 100, 60, 40, 25, 15 },
	ParticipationPoints = 5,

	QueueKioskPosition = Vector3.new(0, 5, -60),
	QueueAreaRadius = 12,

	LeaderboardDataStoreName = "HardcorePack_Stats_v1",
	LeaderboardTopN = 25,
	LeaderboardSaveRetries = 3,
	LeaderboardSaveRetryDelay = 2,
	LeaderboardRequestBudgetPerMinute = 30,

	CollapseProtocol = {
		Center = Vector3.new(1200, 60, 0),
		RingCount = 7,
		HexSize = 4.5,
		HexHeight = 1,
		HexGap = 0.35,
		KillY = -150,
		CrumbleDelay = { Start = 2.2, Finish = 0.6, Min = 0.5 },
		RegrowDelaySeconds = 4,
		RegrowDisabledAfterFraction = 0.66,
		QuakeInterval = { Start = 9, Finish = 3, Min = 2.5 },
		QuakeClusterSize = 5,
		QuakeWarningTime = 1.25,
	},

	SignalJammer = {
		Center = Vector3.new(1500, 60, 0),
		ArenaRadius = 50,
		CapturePointRadius = 8,
		CapturePointSpeed = 6,
		CaptureScorePerSecond = 10,
		PulseTelegraphTime = { Start = 2, Finish = 0.6, Min = 0.4 },
		PulseInterval = { Start = 5, Finish = 2, Min = 1.5 },
		PulseRadius = 14,
		PulseActiveTime = 0.6,
		MultiPulseAfterFraction = 0.6,
	},

	FreefallGauntlet = {
		TopCenter = Vector3.new(1800, 400, 0),
		KillY = -80,
		RingCount = 16,
		RingSpacing = 22,
		RingRadius = 22,
		RingThickness = 3,
		GapSize = { Start = 14, Finish = 6, Min = 5 },
		RotationSpeed = { Start = 20, Finish = 70, Max = 90 },
		WindGustAfterFraction = 0.5,
		WindGustInterval = 6,
		WindGustForce = 40,
	},
}

return Config
