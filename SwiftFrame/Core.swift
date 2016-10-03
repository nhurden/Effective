//
//  Core.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation

public typealias StringMap = [String: Any]
public typealias EffectMap = StringMap
public typealias CoeffectMap = StringMap

public typealias EventHandler<A, S> = (S?, A) -> S
public typealias EffectHandler = (Any) -> ()
public typealias CoeffectHandler = (CoeffectMap) -> CoeffectMap

public protocol CaseName {
    func nameForCase() -> String
}

public struct Context {
    var coeffects: CoeffectMap
    var effects: EffectMap

    let queue: [Interceptor]
    let stack: [Interceptor]
}

public struct Interceptor {
    let name: String
    let before: ((Context) -> Context)?
    let after: ((Context) -> Context)?
}

public class Store<A: CaseName, S> {
    let registry: Registry<A, S>
    let state: S

    init(initialState: S) {
        registry = Registry()
        state = initialState
    }

    public func dispatch(action: A) {
        handleEvent(action: action)
    }

    // Effect Handlers
    public func registerEffect(key: String, handler: @escaping EffectHandler) {
        registry.registerEffectHandler(key: key, handler: handler)
    }

    // Coeffect Handlers
    public func registerCoeffect(key: String, handler: @escaping CoeffectHandler) {
        registry.registerCoeffectHandler(key: key, handler: handler)
    }

    // Event Handlers

    public func registerEventState(key: String, handler: @escaping EventHandler<A, S>) {
        registerEventState(key: key, interceptors: [], handler: handler)
    }

    public func registerEventState(key: String, interceptors: [Interceptor], handler: @escaping EventHandler<A, S>) {
        let withState = [injectState(), doEffects()] + interceptors + [stateHandlerInterceptor(handler: handler)]
        registry.registerEventHandler(key: key, interceptors: withState)
    }

    public func handleEvent(action: A) {
        if let interceptors = registry.eventHandler(action: action) {
            execute(action: action, interceptors: interceptors)
        } else {
            let key = action.nameForCase()
            print("Could not find an event handler for key \(key)")
        }
    }

    // Basic Interceptors

    /// Lookup a coeffect handler and wrap it in a before Interceptor
    public func injectCoeffect(name: String) -> Interceptor {
        if let handler = registry.coeffectHandler(key: name) {
            return Interceptor(name: "coeffect: \(name)", before: { (context: Context) in
                var ctx = context
                ctx.coeffects = handler(context.coeffects)
                return ctx
                }, after: nil)
        } else {
            fatalError("Could not find a coeffect handler for key \(name)")
        }
    }

    /// An interceptor that does all effects in the effects map by calling registered `EffectHandler`s
    public func doEffects() -> Interceptor {
        return Interceptor(name: "doEffects", before: nil, after: { (context: Context) in
            let effects = context.effects
            for (key, value) in effects {
                if let handler = self.registry.effectHandler(key: key) {
                    handler(value)
                } else {
                    fatalError("Could not find an effect handler for key \(key)")
                }
            }
            return context
        })
    }

    public func injectState() -> Interceptor {
        return injectCoeffect(name: "state")
    }

    // Wrapper Interceptors

    /// Wraps an EventHandler in an interceptor that sets the state effect to the handler's return value
    func stateHandlerInterceptor(handler: @escaping EventHandler<A, S>) -> Interceptor {
        return Interceptor(name: "stateHandler", before: { (context: Context) in
            let action = context.coeffects["action"] as! A
            let state = context.coeffects["state"] as? S
            var ctx = context
            ctx.effects["state"] = handler(state, action)
            return ctx
            }, after: nil)
    }
}

/// Execute an interceptor chain starting from an action
func execute<A>(action: A, interceptors: [Interceptor]) {
    // TODO
}
