--!strict
-- Builds a Collapse Protocol arena: a hex-tile floor over a kill void.
-- Purely parametric off Config.CollapseProtocol so difficulty tuning never
-- touches this file. Tiles render as flat cylindrical "pucks" laid out on a
-- true axial hex grid (a literal hexagon mesh would need an imported asset,
-- which this pack avoids); the hex math still drives neighbor/cluster logic.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HexGrid = require(ReplicatedStorage.Hardcore:WaitForChild("HexGrid"))
local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local HardcoreUtils = require(ServerScriptService.Hardcore:WaitForChild("HardcoreUtils"))

local Builder = {}

local function newHexTile(cfg: Config.CollapseProtocolConfig, q: number, r: number): BasePart
	local spacing = cfg.HexSize + cfg.HexGap
	local offset = HexGrid.ToWorldOffset(q, r, spacing)
	local worldPos = cfg.Center + offset

	local tile = Instance.new("Part")
	tile.Name = HexGrid.Key(q, r)
	tile.Anchored = true
	tile.CanCollide = true
	tile.Shape = Enum.PartType.Cylinder
	tile.Material = Enum.Material.Slate
	tile.Color = Color3.fromRGB(110, 112, 122)
	-- Size.X becomes the vertical thickness once rotated 90 degrees below.
	tile.Size = Vector3.new(cfg.HexHeight, cfg.HexSize, cfg.HexSize)
	tile.CFrame = CFrame.new(worldPos) * CFrame.Angles(0, 0, math.rad(90))
	return tile
end

function Builder.Build(parent: Instance): Folder
	local cfg = Config.CollapseProtocol

	local container = Instance.new("Folder")
	container.Name = "CollapseProtocolArena"

	local tiles = Instance.new("Folder")
	tiles.Name = "Tiles"
	tiles.Parent = container

	for _, cell in HexGrid.CellsInRadius(cfg.RingCount) do
		local tile = newHexTile(cfg, cell.Q, cell.R)
		tile.Parent = tiles
	end

	local spectatorPos = cfg.Center + Vector3.new((cfg.RingCount + 4) * (cfg.HexSize + cfg.HexGap) * 1.5, 6, 0)
	HardcoreUtils.BuildSpectatorStand(container, spectatorPos)

	container.Parent = parent
	return container
end

return Builder
