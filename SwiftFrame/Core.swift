//
//  Core.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation
import RxSwift

public typealias StringMap = [String: Any]
public typealias EffectMap = StringMap
public typealias CoeffectMap = StringMap

public typealias EventHandler<A, S> = (S?, A) -> S
public typealias EffectHandler = (Any) -> ()
public typealias CoeffectHandler = (CoeffectMap) -> CoeffectMap
public typealias LoggingFunction = (String) -> ()

public protocol Action {
    static var name: String { get }
}

public struct Context {
    var coeffects: CoeffectMap
    var effects: EffectMap

    var queue: Queue<Interceptor>
    var stack: Stack<Interceptor>
}

public class Store<S: Equatable> {
    let registry: Registry
    var state: S

    init(initialState: S) {
        registry = Registry()
        state = initialState

        registerBuiltinCoeffects()
        registerBuiltinEffects()
    }

    // MARK: - Dispatch

    public func dispatch<A: Action>(action: A) {
        handleEvent(action: action)
    }

    // MARK: -

    // MARK: Effect Handlers
    public func registerEffect(key: String, handler: @escaping EffectHandler) {
        registry.registerEffectHandler(key: key, handler: handler)
    }

    private func registerBuiltinEffects() {
        // Update the store state based on the state in the effect map
        registerEffect(key: "state") { newState in
            if let newStateS = newState as? S {
                self.state = newStateS
            } else {
                fatalError("Failed to convert state to the store's state type")
            }
        }
    }

    // MARK: Coeffect Handlers
    public func registerCoeffect(key: String, handler: @escaping CoeffectHandler) {
        registry.registerCoeffectHandler(key: key, handler: handler)
    }

    private func registerBuiltinCoeffects() {
        // Add the store state to the coeffect map
        registerCoeffect(key: "state") { coeffects in
            var cofx = coeffects
            cofx["state"] = self.state
            return cofx
        }
    }

    // MARK: Event Handlers

    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(actionClass: A.Type, handler: @escaping EventHandler<A, S>) {
        registerEventState(actionClass: actionClass, interceptors: [], handler: handler)
    }

    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(actionClass: A.Type, interceptors: [Interceptor], handler: @escaping EventHandler<A, S>) {
        /// Wraps an EventHandler in an interceptor that sets the state effect to the handler's return value
        func stateHandlerInterceptor<A: Action>(handler: @escaping EventHandler<A, S>) -> Interceptor {
            return Interceptor(name: "stateHandler", before: { (context: Context) in
                let action = context.coeffects["action"] as! A
                let state = context.coeffects["state"] as? S
                var ctx = context
                ctx.effects["state"] = handler(state, action)
                return ctx
                }, after: nil)
        }

        let withState = [injectState(), doEffects()] + interceptors + [stateHandlerInterceptor(handler: handler)]
        registry.registerEventHandler(key: actionClass.name, interceptors: withState)
    }

    public func handleEvent<A: Action>(action: A) {
        if let interceptors = registry.eventHandler(action: action) {
            execute(action: action, interceptors: interceptors)
        } else {
            let key = type(of: action).name
            print("Could not find an event handler for key \(key)")
        }
    }
}
