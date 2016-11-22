//
//  Effects.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

/// Used for dispatching actions later.
public struct DispatchAfter {
    /// The number of seconds to delay dispatching this action.
    public let delaySeconds: Double

    /// The action to dispatch after the delay.
    public let action: Action
}

extension Store {
    // MARK: Effect Handlers
    
    /**
     * Register an effect handler for the effect named `key` that executes the
     * given effect.
     */
    public func registerEffect(key: String, handler: @escaping EffectHandler) {
        registry.registerEffectHandler(key: key, handler: handler)
    }

    func registerBuiltinEffects() {
        // Update the store state based on the state in the effect map
        registerEffect(key: "state") { newState in
            if let newStateS = newState as? S {
                self.state.value = newStateS
            } else {
                fatalError("Failed to convert state to the store's state type")
            }
        }

        // Dispatch a single action.
        registerEffect(key: "dispatch") { action in
            if let action = action as? Action {
                self.handleEvent(action: action)
            }
        }

        // Dispatch an action after a delay.
        registerEffect(key: "dispatchAfter") { dispatchAfter in
            if let dispatchAfter = dispatchAfter as? DispatchAfter {
                DispatchQueue.main.asyncAfter(deadline: .now() + dispatchAfter.delaySeconds) {
                    self.handleEvent(action: dispatchAfter.action)
                }
            }
        }

        // Dispatch an array of actions.
        registerEffect(key: "dispatchMultiple") { actions in
            if let actions = actions as? [Action] {
                for action in actions {
                    self.handleEvent(action: action)
                }
            }
        }
    }

    /// An interceptor that does all effects in the effects map by calling registered `EffectHandler`s
    public func doEffects() -> Interceptor {
        return Interceptor.after(name: "doEffects") { context in
            let effects = context.effects
            for (key, value) in effects {
                if let handler = self.registry.effectHandler(key: key) {
                    handler(value)
                } else {
                    fatalError("Could not find an effect handler for key \(key)")
                }
            }
            return context
        }
    }
}
