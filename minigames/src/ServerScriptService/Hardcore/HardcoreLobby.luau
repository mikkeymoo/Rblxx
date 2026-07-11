--!strict
-- Builds the physical queue kiosk that lets players opt into the Hardcore
-- pack without disturbing the base pack's own lobby/loop: touching it (or
-- firing RequestJoinQueue from the client UI) enqueues the player, and only
-- queued players are ever pulled into a Hardcore round.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local Matchmaking = require(script.Parent:WaitForChild("Matchmaking"))

local HardcoreLobby = {}

function HardcoreLobby.Build(): Model
	local kiosk = Instance.new("Model")
	kiosk.Name = "HardcorePackKiosk"

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.Neon
	base.Color = Color3.fromRGB(200, 40, 40)
	base.Size = Vector3.new(8, 1, 8)
	base.CFrame = CFrame.new(Config.QueueKioskPosition - Vector3.new(0, 3, 0))
	base.Parent = kiosk

	local pillar = Instance.new("Part")
	pillar.Name = "Pillar"
	pillar.Anchored = true
	pillar.CanCollide = false
	pillar.Material = Enum.Material.Metal
	pillar.Color = Color3.fromRGB(30, 30, 35)
	pillar.Size = Vector3.new(2, 6, 2)
	pillar.CFrame = CFrame.new(Config.QueueKioskPosition)
	pillar.Parent = kiosk

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QueueDisplay"
	billboard.Size = UDim2.new(6, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pillar

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "HARDCORE PACK\nTouch to queue (0 waiting)"
	label.Parent = billboard

	local function refreshLabel()
		label.Text = `HARDCORE PACK\nTouch to queue ({Matchmaking.GetQueueCount()} waiting)`
	end

	base.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			Matchmaking.JoinQueue(player)
		end
	end)

	Matchmaking.QueueChanged:Connect(refreshLabel)

	kiosk.Parent = Workspace
	return kiosk
end

return HardcoreLobby
