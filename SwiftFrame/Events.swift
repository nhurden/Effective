//
//  Events.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation

extension Store {
    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(actionClass: A.Type, handler: @escaping EventHandlerState<A, S>) {
        registerEventState(actionClass: actionClass, interceptors: [], handler: handler)
    }

    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(actionClass: A.Type, interceptors: [Interceptor],
                                   handler: @escaping EventHandlerState<A, S>) {

        /// Wraps an EventHandler in an interceptor that sets the state effect to the handler's return value
        let stateHandlerInterceptor =
            Interceptor(name: "stateHandler",
                        before: stateBeforeUpdater(handler: handler),
                        after: nil)

        let withState = [injectState(), doEffects()] + interceptors + [stateHandlerInterceptor]
        registry.registerEventHandler(key: actionClass.name, interceptors: withState)
    }

    /// Register an event handler that causes effects
    public func registerEventEffects<A: Action>(actionClass: A.Type, handler: @escaping EventHandlerEffects<A>) {
        registerEventEffects(actionClass: actionClass, interceptors: [], handler: handler)
    }

    /// Register an event handler that causes effects
    public func registerEventEffects<A: Action>(actionClass: A.Type, interceptors: [Interceptor],
                                   handler: @escaping EventHandlerEffects<A>) {
        
        /// Wraps an EventHandler in an interceptor that sets the context's effects to the handler's return value
        let effectsHandlerInterceptor =
            Interceptor(name: "effectsHandler",
                        before: effectsBeforeUpdater(handler: handler),
                        after: nil)

        let withState = [injectState(), doEffects()] + interceptors + [effectsHandlerInterceptor]
        registry.registerEventHandler(key: actionClass.name, interceptors: withState)
    }

    public func handleEvent<A: Action>(action: A) {
        if let interceptors = registry.eventHandler(action: action) {
            execute(action: action, interceptors: interceptors)
        } else {
            let key = type(of: action).name
            fatalError("Could not find an event handler for key \(key)")
        }
    }
    
    private func stateBeforeUpdater<A, S>(handler: @escaping EventHandlerState<A, S>) -> ContextUpdater {
        return effectsBeforeUpdater() { (coeffects, action: A) in
            let state = coeffects["state"] as? S
            return ["state": handler(state, action)]
        }
    }

    private func effectsBeforeUpdater<A>(handler: @escaping EventHandlerEffects<A>) -> ContextUpdater {
        return { context in
            let action = context.coeffects["action"] as! A
            var ctx = context
            ctx.effects = handler(context.coeffects, action)
            return ctx
        }
    }
}
