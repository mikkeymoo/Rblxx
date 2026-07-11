--!strict
-- Minimal Signal utility wrapping a BindableEvent, so server modules can
-- expose "round decided" / "state changed" style events instead of polling.
-- Self-authored: see Trove.luau for why this isn't a Wally package.

export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> RBXScriptConnection,
	Once: (self: Signal, fn: (...any) -> ()) -> RBXScriptConnection,
	Wait: (self: Signal) -> ...any,
	Fire: (self: Signal, ...any) -> (),
	Destroy: (self: Signal) -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	local self = setmetatable({
		_bindable = Instance.new("BindableEvent"),
	}, Signal)
	return (self :: any) :: Signal
end

function Signal:Connect(fn: (...any) -> ()): RBXScriptConnection
	return (self :: any)._bindable.Event:Connect(function(argsTable)
		fn(table.unpack(argsTable, 1, argsTable.n))
	end)
end

function Signal:Once(fn: (...any) -> ()): RBXScriptConnection
	local connection: RBXScriptConnection
	connection = (self :: any)._bindable.Event:Connect(function(argsTable)
		connection:Disconnect()
		fn(table.unpack(argsTable, 1, argsTable.n))
	end)
	return connection
end

function Signal:Wait(): ...any
	local argsTable = (self :: any)._bindable.Event:Wait()
	return table.unpack(argsTable, 1, argsTable.n)
end

function Signal:Fire(...: any)
	(self :: any)._bindable:Fire(table.pack(...))
end

function Signal:Destroy()
	(self :: any)._bindable:Destroy()
end

return Signal
