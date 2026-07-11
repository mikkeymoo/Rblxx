--!strict
-- Pure axial hex-grid math shared by Collapse Protocol's map builder and its
-- minigame logic (tile placement, neighbor lookups for quake clusters).
-- Pointy-top axial layout: https://www.redblobgames.com/grids/hexagons/

local HexGrid = {}

export type Axial = { Q: number, R: number }

local NEIGHBOR_OFFSETS: { Axial } = {
	{ Q = 1, R = 0 },
	{ Q = 1, R = -1 },
	{ Q = 0, R = -1 },
	{ Q = -1, R = 0 },
	{ Q = -1, R = 1 },
	{ Q = 0, R = 1 },
}

function HexGrid.Key(q: number, r: number): string
	return `{q},{r}`
end

function HexGrid.ToWorldOffset(q: number, r: number, hexSpacing: number): Vector3
	local x = hexSpacing * (3 / 2 * q)
	local z = hexSpacing * (math.sqrt(3) / 2 * q + math.sqrt(3) * r)
	return Vector3.new(x, 0, z)
end

function HexGrid.Distance(q1: number, r1: number, q2: number, r2: number): number
	local x1, z1, y1 = q1, r1, -q1 - r1
	local x2, z2, y2 = q2, r2, -q2 - r2
	return (math.abs(x1 - x2) + math.abs(y1 - y2) + math.abs(z1 - z2)) / 2
end

function HexGrid.Neighbors(q: number, r: number): { Axial }
	local result = {}
	for _, offset in NEIGHBOR_OFFSETS do
		table.insert(result, { Q = q + offset.Q, R = r + offset.R })
	end
	return result
end

-- Every axial cell within `ringCount` rings of the origin (inclusive), origin included.
function HexGrid.CellsInRadius(ringCount: number): { Axial }
	local cells = {}
	for q = -ringCount, ringCount do
		for r = -ringCount, ringCount do
			if HexGrid.Distance(0, 0, q, r) <= ringCount then
				table.insert(cells, { Q = q, R = r })
			end
		end
	end
	return cells
end

return HexGrid
