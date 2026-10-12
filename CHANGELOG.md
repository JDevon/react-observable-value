# Changelog

## 0.1.0

- Initial release:
  - `useObservableValue`: returns an ObservableValue's current value and an update id, and rerenders the
    component whenever the value changes.
  - `useObservableBinding`: returns a React binding that follows an ObservableValue without rerendering.
  - `useObservableSelector`: returns part of an ObservableValue and rerenders only when that part changes.
