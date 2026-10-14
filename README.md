<!-- Links -->

[react-observable-value/releases]: https://github.com/JDevon/react-observable-value/releases/latest
[react-observable-value/wally]: https://wally.run/package/jdevon/react-observable-value

<!-- Badges -->

[badges/github]: https://raw.githubusercontent.com/gist/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/github.svg
[badges/wally]: https://raw.githubusercontent.com/gist/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/wally.svg

# ReactObservableValue

React hooks for [ObservableValue](https://github.com/JDevon/observable-value). Rerender when a value changes, rerender
only when part of it changes, or update a binding without rerendering.

Full API reference at [jdevon.github.io/react-observable-value](https://jdevon.github.io/react-observable-value/).

## Install

[![badges/github]][react-observable-value/releases] [![badges/wally]][react-observable-value/wally]

Install with [Wally](https://wally.run) by adding both packages to your `wally.toml`:

```toml
[dependencies]
ObservableValue = "jdevon/observable-value@0.1.0"
ReactObservableValue = "jdevon/react-observable-value@0.1.0"
```

ReactObservableValue only provides the hooks; you create values with ObservableValue. Wally installs a single copy
of ObservableValue when both versions are compatible, so the hooks and your code share the same class.

## Usage

```lua
local React = require(ReplicatedStorage.Packages.React)
local ObservableValue = require(ReplicatedStorage.Packages.ObservableValue)
local ReactObservableValue = require(ReplicatedStorage.Packages.ReactObservableValue)

local health = ObservableValue.new(100)

local function HealthLabel()
    -- rerenders whenever health changes
    local currentHealth = ReactObservableValue.useObservableValue(health)

    return React.createElement("TextLabel", {
        Text = `{currentHealth} HP`,
    })
end

health:set(80) -- every mounted HealthLabel now shows 80 HP
```

The second return value increases every time the value changes. Use it as a dependency when a table value may have
been changed in place:

```lua
local inventory = ObservableValue.new({} :: { [string]: number })

local function ItemCount()
    local items, updateId = ReactObservableValue.useObservableValue(inventory)

    local total = React.useMemo(function()
        local count = 0
        for _, quantity in items do
            count += quantity
        end
        return count
    end, { updateId })

    return React.createElement("TextLabel", {
        Text = `{total} items`,
    })
end
```

For values that change often, `useObservableBinding` follows the value with a React binding instead of rerendering:

```lua
local progress = ObservableValue.new(0)

local function ProgressBar()
    local progressBinding = ReactObservableValue.useObservableBinding(progress)

    return React.createElement("Frame", {
        Size = progressBinding:map(function(value)
            return UDim2.fromScale(value, 1)
        end),
    })
end
```

To rerender only when part of a value changes, `useObservableSelector` returns what your selector picks out:

```lua
local blurStack = ObservableValue.new({} :: { [number]: true })

local function BlurOverlay()
    -- rerenders only when the stack goes from empty to not empty, or back
    local isVisible = ReactObservableValue.useObservableSelector(blurStack, function(stack)
        return next(stack) ~= nil
    end)

    return React.createElement("Frame", {
        Visible = isVisible,
    })
end
```

Results are compared with `==`. Pass an `isEqual` function as the third argument if your selector builds a new
table each time.

## API

Each member links to its full entry in the [API reference](https://jdevon.github.io/react-observable-value/api/ReactObservableValue).

### Functions

- [`.useObservableValue`](https://jdevon.github.io/react-observable-value/api/ReactObservableValue#useObservableValue) - returns an ObservableValue's current value and an update id, and rerenders the
    component whenever the value changes.
- [`.useObservableBinding`](https://jdevon.github.io/react-observable-value/api/ReactObservableValue#useObservableBinding) - returns a React binding that follows an ObservableValue without rerendering
- [`.useObservableSelector`](https://jdevon.github.io/react-observable-value/api/ReactObservableValue#useObservableSelector) - returns part of an ObservableValue and rerenders only when that part changes
