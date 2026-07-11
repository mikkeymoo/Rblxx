--!strict
-- leaderstats coin tracking backed by DataStoreService, with a pcall'd load/save
-- and an in-memory session cache so writes don't hit the DataStore every award.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local CoinStore = DataStoreService:GetDataStore("MinigamesCoins_v1")

local PlayerData = {}

local sessionCache: { [number]: number } = {}

local function loadCoins(player: Player): number
	local success, result = pcall(function()
		return CoinStore:GetAsync("Player_" .. player.UserId)
	end)
	if success and type(result) == "number" then
		return result
	end
	return 0
end

local function saveCoins(player: Player, coins: number)
	local success, err = pcall(function()
		CoinStore:SetAsync("Player_" .. player.UserId, coins)
	end)
	if not success then
		warn(`[PlayerData] Failed to save coins for {player.Name}: {tostring(err)}`)
	end
end

function PlayerData.Init(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = loadCoins(player)
	coins.Parent = leaderstats

	sessionCache[player.UserId] = coins.Value
end

function PlayerData.AddCoins(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		return
	end
	local intValue = coins :: IntValue
	intValue.Value += amount
	sessionCache[player.UserId] = intValue.Value
end

function PlayerData.Save(player: Player)
	local cached = sessionCache[player.UserId]
	if cached ~= nil then
		saveCoins(player, cached)
	end
	sessionCache[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.Save(player)
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerData.Save(player)
	end
end)

return PlayerData
