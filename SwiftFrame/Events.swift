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
