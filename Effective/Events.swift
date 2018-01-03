//
//  Events.swift
//  Effective
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

extension Store {
    // MARK: Event Handlers

    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(actionClass: A.Type, handler: @escaping EventHandlerState<A, S>) {
        registerEventState(actionClass: actionClass, interceptors: [], handler: handler)
    }

    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(
        actionClass: A.Type,
        interceptors: [Interceptor],
        handler: @escaping EventHandlerState<A, S>) {

        registerEventContext(actionClass: actionClass,
                             interceptors: interceptors,
                             handler: stateBeforeUpdater(handler: handler))
    }

    /// Register an event handler that causes effects
    public func registerEventEffects<A: Action>(actionClass: A.Type, handler: @escaping EventHandlerEffects<A>) {
        registerEventEffects(actionClass: actionClass, interceptors: [], handler: handler)
    }

    /// Register an event handler that causes effects
    public func registerEventEffects<A: Action>(
        actionClass: A.Type,
        interceptors: [Interceptor],
        handler: @escaping EventHandlerEffects<A>) {

        registerEventContext(actionClass: actionClass,
                             interceptors: interceptors,
                             handler: effectsBeforeUpdater(handler: handler))
    }

    /// Register an event handler that directly updates the context.
    func registerEventContext<A: Action>(actionClass: A.Type, handler: @escaping EventHandlerContext) {
        registerEventContext(actionClass: actionClass, interceptors: [], handler: handler)
    }

    /// Register an event handler that directly updates the context.
    func registerEventContext<A: Action>(
        actionClass: A.Type,
        interceptors: [Interceptor],
        handler: @escaping EventHandlerContext) {

        // Wrap the context update in an interceptor (choice of before/after is arbitrary)
        let handlerInterceptor = Interceptor.before(name: "handler", before: handler)

        // Inject the event handler after all other interceptors
        let withState = [injectState(), doEffects()] + interceptors + [handlerInterceptor]
        registry.registerEventHandler(key: actionClass.typeName, interceptors: withState)
    }

    /// Handle an event
    func handleEvent(action: Action) {
        if let interceptors = registry.eventHandler(action: action) {
            execute(action: action, interceptors: interceptors)
        } else {
            let key = action.typeName
            fatalError("Could not find an event handler for key \(key)")
        }
    }

    private func stateBeforeUpdater<A, S>(handler: @escaping EventHandlerState<A, S>) -> ContextUpdater {
        return effectsBeforeUpdater { (coeffects, action: A) in
            guard let state = coeffects["state"] else {
                fatalError("Attempting to call an event handler that expects state with no state in the coeffect map")
            }

            if let state = state as? S {
                return ["state": handler(state, action)]
            } else {
                fatalError("State was not of the store's state type")
            }
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
