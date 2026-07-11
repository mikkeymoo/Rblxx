--!strict
-- Turns a Config.EscalationCurve plus an elapsed/total time fraction into a
-- concrete tunable value. Shared by every minigame so difficulty curves are
-- computed the same way everywhere instead of copy-pasted lerp math.
local Config = require(script.Parent:WaitForChild("Config"))

local Escalation = {}

function Escalation.Clamp01(fraction: number): number
	return math.clamp(fraction, 0, 1)
end

-- Linearly interpolates Start -> Finish over `fraction` (0..1), then clamps
-- to Min/Max if the curve declares them.
function Escalation.Evaluate(curve: Config.EscalationCurve, fraction: number): number
	local f = Escalation.Clamp01(fraction)
	local value = curve.Start + (curve.Finish - curve.Start) * f
	if curve.Min ~= nil then
		value = math.max(value, curve.Min :: number)
	end
	if curve.Max ~= nil then
		value = math.min(value, curve.Max :: number)
	end
	return value
end

-- Elapsed-seconds convenience wrapper around Evaluate.
function Escalation.EvaluateElapsed(curve: Config.EscalationCurve, elapsedSeconds: number, totalSeconds: number): number
	if totalSeconds <= 0 then
		return curve.Finish
	end
	return Escalation.Evaluate(curve, elapsedSeconds / totalSeconds)
end

return Escalation
