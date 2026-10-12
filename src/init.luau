--!strict
local React = require(script.Parent.React)
local ObservableValue = require(script.Parent.ObservableValue)

--[=[
	@class ReactObservableValue

	React hooks for [ObservableValue](https://jdevon.github.io/observable-value/). Rerender when a value changes,
	rerender only when part of it changes, or update a binding without rerendering.
]=]
local ReactObservableValue = {}

--[=[
	@within ReactObservableValue

	Returns the ObservableValue’s current value, and rerenders the component whenever it changes. The second return value
	increases on every change so it can be used as a `useMemo` / `useEffect` dependency even when a table was
	changed in place.

	```lua
	local function HealthBar(props: { health: ObservableValue.ObservableValue<number> })
		local health = ReactObservableValue.useObservableValue(props.health)
		return React.createElement("TextLabel", { Text = `{health} HP` })
	end
	```

	@param source ObservableValue<T>
	@return T -- the current value
	@return number -- increases every time the value changes
]=]
function ReactObservableValue.useObservableValue<T>(source: ObservableValue.ObservableValue<T>): (T, number)
	local renderedValue = source:get()
	local updateId, setUpdateId = React.useState(0)

	React.useEffect(function()
		local isInitialCall = true
		return source:observe(function(value)
			if isInitialCall then
				isInitialCall = false
				if value == renderedValue then
					return
				end
			end
			setUpdateId(function(id)
				return id + 1
			end)
		end)
	end, { source })

	return renderedValue, updateId
end

--[=[
	@within ReactObservableValue

	Returns a React binding that follows the ObservableValue without rerendering the component. Bindings update
	instance properties directly, which suits values that change often, like progress bars and timers. Use the
	binding's `map` to turn the value into a property.

	```lua
	local function ProgressBar(props: { progress: ObservableValue.ObservableValue<number> })
		local progress = ReactObservableValue.useObservableBinding(props.progress)
		return React.createElement("Frame", {
			Size = progress:map(function(value)
				return UDim2.fromScale(value, 1)
			end),
		})
	end
	```

	@param source ObservableValue<T>
	@return Binding<T>
]=]
function ReactObservableValue.useObservableBinding<T>(source: ObservableValue.ObservableValue<T>): React.Binding<T>
	local binding, setBinding = React.useBinding(source:get())

	React.useEffect(function()
		return source:observe(function(value)
			setBinding(value)
		end)
	end, { source })

	return binding
end

--[=[
	@within ReactObservableValue

	Returns `selector(value)` and rerenders the component only when that result changes, not on every change to the
	ObservableValue. Use it to read part of a table, or something computed from the value.

	Results are compared with `==` unless you pass `isEqual`. A selector that builds a new table each time needs an
	`isEqual`, or it rerenders on every change.

	```lua
	local function BlurOverlay(props: { blurStack: ObservableValue.ObservableValue<{ [number]: true }> })
		local isVisible = ReactObservableValue.useObservableSelector(props.blurStack, function(stack)
			return next(stack) ~= nil
		end)
		return React.createElement("Frame", { Visible = isVisible })
	end
	```

	@param source ObservableValue<T>
	@param selector (value: T) -> U
	@param isEqual ((previous: U, current: U) -> boolean)?
	@return U
]=]
function ReactObservableValue.useObservableSelector<T, U>(
	source: ObservableValue.ObservableValue<T>,
	selector: (value: T) -> U,
	isEqual: ((previous: U, current: U) -> boolean)?
): U
	local selected = selector(source:get())
	local _, setUpdateId = React.useState(0)

	local selectorRef = React.useRef(selector)
	local isEqualRef = React.useRef(isEqual)
	local selectedRef = React.useRef(selected)
	selectorRef.current = selector
	isEqualRef.current = isEqual
	selectedRef.current = selected

	React.useEffect(function()
		return source:observe(function(value)
			local nextSelected = selectorRef.current(value)
			local compare = isEqualRef.current
			local changed = if compare
				then not compare(selectedRef.current, nextSelected)
				else selectedRef.current ~= nextSelected
			if changed then
				selectedRef.current = nextSelected
				setUpdateId(function(id)
					return id + 1
				end)
			end
		end)
	end, { source })

	return selected
end

return table.freeze(ReactObservableValue)
