# Effective
A Swift state container library with extensible effects, modelled after [re-frame][rf].

## Table of Contents
- [Features](#features)
- [Basic Usage](#basic-usage)
- [Effects](#effects)
- [Coeffects](#coeffects)
- [Interceptors](#interceptors)
- [Installation](#installation)

## Features
- [RxSwift][Rx] for observation of store changes
- Immutable store state
- Isolation of effects within effects handlers, keeping event handlers pure and allowing for effect reuse
- A flexible context and [interceptor][int] based execution model that allows for
individual actions to be extended (rather than the entire store)

## Basic Usage
### 1. Define your app state:
#### Create a struct:
```swift
struct AppState {
    var todos: [String] = []
}
```

_Note: Make sure to declare state properties as `var` rather than `let` to make
writing your event handlers less cumbersome_

#### Extend Equatable:
```swift
extension AppState: Equatable {}

func == (lhs: AppState, rhs: AppState) -> Bool {
    return lhs.todos == rhs.todos
}
```

### 2. Define actions:
Actions in Effective are simple structs tagged with the `Action` protocol:
```swift
struct AddTodo: Action {
    let name: String
}
```

### 3. Create a store:
```swift
let store = Store(initialState: AppState())
```

### 4. Register event handlers:
`registerEventState` registers a handler for an action of the given `actionClass`
of the following shape: `(State, Action) -> State`.

```swift
store.registerEventState(actionClass: AddTodo.self) { (state, action) in
    var s = state
    s.todos.append(action.name)
    return s
}
```

_Note that since `state` is immutable, `state` is first copied to `s`._

### 5. Observe the store:
Specific keypaths can be observed from the store using `store.observe`:
```swift
let todos: Driver<[String]> = store.observe(keyPath: \.todos, comparer: ==)
```
_Note that `==` only needs to be passed here since [``Array`` is currently not `Equatable`][cc].
When observing values that are `Equatable`, `comparer` is not required._

### 6. Dispatch actions:
```swift
store.dispatch(AddTodo(name: "Dispatch more actions"))
```

## Effects
Event handlers should avoid having side-effects, both for ease of testing and
for isolation of individual effects.

Event handlers that perform side-effects should be registered using `registerEventEffects`
rather than `registerEventState` and return an `EffectMap` (see below) rather than a
new state. By returning descriptions of effects rather than executing them, event
handlers can be kept pure and effects can be easily stubbed out for testing by calling `registerEffect`.

### Using Effects
#### 1a. Register a type to describe your effect (optional)
```swift
enum CounterEffect {
    case increment
    case decrement
}
```

#### 1b. Register an effect handler
An effect handler performs arbitrary side-effects given an arbitrary input (of type `Any`):

```swift
var actionsAdded = 0
store.registerEffect(key: "counter") { action in
    if let action = action as? CounterEffect {
        switch action {
        case .increment:
            actionsAdded += 1
        }
    }
}
```

_Note that the key used to register the effect handler must match the name of the
effect returned in the `EffectMap` below._

#### 2. Return effects from an event handler
`registerEventEffects` registers a handler for an action of the given `actionClass`
of the following shape: `(CoeffectMap, Action) -> EffectMap`.

The values for each key are the `EffectMap` are passed to the effect handler
for the corresponding key (in this case `"counter"` is passed `CounterEffect.increment`).

```swift
struct AddTodoAndIncrement: Action { … }

store.registerEventEffects(actionClass: AddTodoAndIncrement.self) { coeffects, action in
    let state = coeffects["state"] as? AppState
    var newState = state ?? AppState()
    newState.todos.append(action.name)

    return [ "counter": CounterEffect.increment,
             "state": newState ]
}
```

### Built-in Effects
#### `dispatch`
The `dispatch` effect simply dispatches its argument immediately:

```swift
struct PreAddTodo: Action { … }

// Dispatches AddTodo immediately
store.registerEventEffects(actionClass: PreAddTodo.self) { coeffects, action in
    return [ "dispatch": AddTodo(name: action.name)]
}
```

#### `dispatchAfter`
The `dispatchAfter` effect dispatches its action after a delay, specified by a `DispatchAfter`:

```swift
struct AddTodoLater: Action { … }

// Dispatches AddTodo after a delay
store.registerEventEffects(actionClass: AddTodoLater.self) { coeffects, action in
    return [ "dispatchAfter": DispatchAfter(delaySeconds: action.delay,
                                            action: AddTodo(name: action.name))]
}
```

#### `dispatchMultiple`
The `dispatchMultiple` effect dispatches multiple actions immediately:

```swift
struct AddTodos: Action { … }

// Dispatches AddTodo twice
store.registerEventEffects(actionClass: AddTodos.self) { coeffects, action in
    let actions = [AddTodo(name: action.name), AddTodo(name: action.name.uppercased())]
    return [ "dispatchMultiple": actions]
}
```


#### `state`
The `state` effect replaces the store's state with its argument:

```swift
// `state` as effect
store.registerEventEffects(actionClass: AddTodo.self) { coeffects, action in
    let state = coeffects["state"] as? AppState
    var newState = state ?? AppState()
    newState.todos.append(action.name)

    return [ "state": newState ]
}

// `state` is implied:
store.registerEventState(actionClass: AddTodo.self) { state, action in
    var s = state
    s.todos.append(action.name)
    return s
}
```

This is done implicitly when using `registerEventState` but needs to be done explicitly when using `registerEventEffects`.

## Coeffects
Just as effect handlers handle the _outputs_ of event handlers, coeffect handlers handle the _inputs_ to event handlers.
Coeffects injected by `registerCoeffect` are available within event handlers registered with `registerEventEffects`:

```swift
// 1. Register the value for the coeffect (with a value or closure)
store.registerCoeffect(key: "time", value: NSDate())

// 2. Create an interceptor to inject the coeffect
let injectTime = store.injectCoeffect(name: "time")

// 3. Add the interceptor to the event handler
store.registerEventEffects(actionClass: AddTodo.self, interceptors: [injectTime]) { coeffects, action in
    let state = coeffects["state"] as? AppState
    var newState = state ?? AppState()

    // 4. Extract the coeffect in the event handler
    let time = coeffects["time"] as? NSDate
    let todoName = String(describing: time) + " " + action.name
    newState.todos.append(todoName)

    return [ "state": newState ]
}
```

By injecting inputs to event handlers through coeffects, individual coeffects can be replaced
for testing by calling `registerCoeffect` with a stub handler implementation.

## Interceptors

### Built-in Interceptors
#### `enrich`
The `enrich` interceptor runs a function to transform the store's state after a given action:

```swift
// Deduplicate `todos` after each addition
let dedup = store.enrich(actionClass: AddTodo.self) { state, action in
    let newTodos = Array(Set(state.todos))
    return AppState(todos: newTodos)
}

store.registerEventState(actionClass: AddTodo.self, interceptors: [dedup]) { state, action in
    var s = state
    s.todos.append(action.name)
    return s
}
```

#### `after`
The `after` interceptor runs a function for side-effects after the event handler:

```swift
// Increment a counter after each action
var actionsAdded = 0
let inc = store.after(actionClass: AddTodo.self) { state, action in
    actionsAdded += 1
}

store.registerEventState(actionClass: AddTodo.self, interceptors: [inc]) { state, action in
    var s = state
    s.todos.append(action.name)
    return s
}
```

#### `debug`
The `debug` interceptor wraps each action, printing actions and their state changes:
```swift
store.registerEventState(actionClass: Increment.self, interceptors: [debug]) { s, _ in s + 1 }
store.dispatch(Increment()) // => Handling action: Increment():
                            //      Old State: 1
                            //      New State: 2
```

## Installation
### CocoaPods
Add `pod 'Effective',  '~> 0.0.1'` to your Podfile and run `pod install`.

Then `import Effective`.

  [rf]: https://github.com/Day8/re-frame/ "re-frame"
  [Rx]: https://github.com/ReactiveX/RxSwift "RxSwift"
  [int]: http://pedestal.io/reference/interceptors "Interceptors"
  [cc]: https://github.com/apple/swift-evolution/blob/master/proposals/0143-conditional-conformances.md
