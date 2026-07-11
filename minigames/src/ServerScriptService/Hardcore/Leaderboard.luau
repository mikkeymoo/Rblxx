--!strict
-- Persistent Hardcore pack stats: wins, points, best placement, games played.
-- Every DataStore call is pcall-wrapped, writes go through UpdateAsync so
-- concurrent sessions merge instead of clobbering, a session cache means
-- RecordRoundResult never yields the round loop, and a token-bucket budgets
-- writes per minute so a burst of round-ends can't blow the DataStore limit.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage.Hardcore:WaitForChild("Remotes"))
local HardcoreUtils = require(script.Parent:WaitForChild("HardcoreUtils"))

local Leaderboard = {}

export type Stats = {
	Wins: number,
	Points: number,
	BestPlacement: number,
	GamesPlayed: number,
}

export type TopNEntry = {
	Name: string,
	Points: number,
}

local DEFAULT_STATS: Stats = { Wins = 0, Points = 0, BestPlacement = 0, GamesPlayed = 0 }
local TOP_N_CACHE_TTL = 5

local mainStore = DataStoreService:GetDataStore(Config.LeaderboardDataStoreName)
local orderedStore = DataStoreService:GetOrderedDataStore(Config.LeaderboardDataStoreName .. "_Points")

local sessionCache: { [number]: Stats } = {}

local budgetTokens = Config.LeaderboardRequestBudgetPerMinute
local lastRefill = os.clock()

local cachedTopN: { TopNEntry }? = nil
local cachedTopNAt = 0

local function takeBudgetToken(): boolean
	local now = os.clock()
	if now - lastRefill >= 60 then
		budgetTokens = Config.LeaderboardRequestBudgetPerMinute
		lastRefill = now
	end
	if budgetTokens <= 0 then
		return false
	end
	budgetTokens -= 1
	return true
end

local function keyFor(player: Player): string
	return `Player_{player.UserId}`
end

local function loadStats(player: Player): Stats
	local success, result = pcall(function()
		return mainStore:GetAsync(keyFor(player))
	end)
	if success and type(result) == "table" then
		local data = result :: { [string]: number }
		return {
			Wins = data.Wins or 0,
			Points = data.Points or 0,
			BestPlacement = data.BestPlacement or 0,
			GamesPlayed = data.GamesPlayed or 0,
		}
	end
	return table.clone(DEFAULT_STATS)
end

local function saveStats(player: Player, stats: Stats)
	if not takeBudgetToken() then
		task.delay(5, function()
			if player.Parent then
				saveStats(player, stats)
			end
		end)
		return
	end

	local attempts = 0
	local success = false
	while attempts < Config.LeaderboardSaveRetries and not success do
		attempts += 1
		success = pcall(function()
			mainStore:UpdateAsync(keyFor(player), function(old)
				local base = if type(old) == "table" then old :: { [string]: number } else nil
				return {
					Wins = math.max((base and base.Wins) or 0, stats.Wins),
					Points = math.max((base and base.Points) or 0, stats.Points),
					BestPlacement = if base and base.BestPlacement and base.BestPlacement > 0
						then math.min(base.BestPlacement, stats.BestPlacement)
						else stats.BestPlacement,
					GamesPlayed = math.max((base and base.GamesPlayed) or 0, stats.GamesPlayed),
				}
			end)
		end)
		if not success then
			task.wait(Config.LeaderboardSaveRetryDelay)
		end
	end

	if success then
		pcall(function()
			orderedStore:SetAsync(keyFor(player), stats.Points)
		end)
	else
		warn(`[Leaderboard] Failed to save stats for {player.Name} after {attempts} attempts`)
	end
end

function Leaderboard.Init(player: Player)
	task.spawn(function()
		sessionCache[player.UserId] = loadStats(player)
	end)
end

function Leaderboard.RecordRoundResult(player: Player, placement: number, pointsEarned: number, won: boolean)
	local stats = sessionCache[player.UserId] or table.clone(DEFAULT_STATS)
	stats.Points += pointsEarned
	stats.GamesPlayed += 1
	if won then
		stats.Wins += 1
	end
	if stats.BestPlacement == 0 or placement < stats.BestPlacement then
		stats.BestPlacement = placement
	end
	sessionCache[player.UserId] = stats

	task.spawn(function()
		saveStats(player, stats)
	end)
end

function Leaderboard.Flush(player: Player)
	local stats = sessionCache[player.UserId]
	if stats then
		saveStats(player, stats)
	end
	sessionCache[player.UserId] = nil
end

function Leaderboard.GetTopN(n: number): { TopNEntry }
	if cachedTopN and (os.clock() - cachedTopNAt) < TOP_N_CACHE_TTL then
		return cachedTopN
	end

	local success, pagesOrErr = pcall(function()
		return orderedStore:GetSortedAsync(false, n)
	end)
	if not success then
		warn("[Leaderboard] GetSortedAsync failed:", pagesOrErr)
		return cachedTopN or {}
	end

	local page = (pagesOrErr :: DataStorePages):GetCurrentPage()
	local results: { TopNEntry } = {}
	for _, entry in page do
		local userId = tonumber(string.match(entry.key, "%d+"))
		local name = "Player"
		if userId then
			local ok, result = pcall(function()
				return Players:GetNameFromUserIdAsync(userId :: number)
			end)
			if ok and type(result) == "string" then
				name = result
			end
		end
		table.insert(results, { Name = name, Points = entry.value })
	end

	cachedTopN = results
	cachedTopNAt = os.clock()
	return results
end

function Leaderboard.GetSnapshot(player: Player): { TopN: { TopNEntry }, Self: Stats }
	return {
		TopN = Leaderboard.GetTopN(Config.LeaderboardTopN),
		Self = sessionCache[player.UserId] or table.clone(DEFAULT_STATS),
	}
end

function Leaderboard.BindRemote()
	local rateLimited = HardcoreUtils.NewRateLimiter(2, 5)
	Remotes.GetFunction("GetLeaderboardSnapshot").OnServerInvoke = function(player: Player)
		if not rateLimited(player) then
			return { TopN = cachedTopN or {}, Self = sessionCache[player.UserId] or table.clone(DEFAULT_STATS) }
		end
		return Leaderboard.GetSnapshot(player)
	end
end

Players.PlayerRemoving:Connect(function(player)
	Leaderboard.Flush(player)
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		Leaderboard.Flush(player)
	end
end)

return Leaderboard
