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

public struct Interceptor {
    let name: String
    let before: ((Context) -> Context)?
    let after: ((Context) -> Context)?
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

    public func dispatch<A: Action>(action: A) {
        handleEvent(action: action)
    }

    // Effect Handlers
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

    // Coeffect Handlers
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

    // Event Handlers

    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(actionClass: A.Type, handler: @escaping EventHandler<A, S>) {
        registerEventState(actionClass: actionClass, interceptors: [], handler: handler)
    }

    /// Register an event handler that causes a state update and has no side effects
    public func registerEventState<A: Action>(actionClass: A.Type, interceptors: [Interceptor], handler: @escaping EventHandler<A, S>) {
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

    // Basic Interceptors

    /// Lookup a coeffect handler and wrap it in a before Interceptor
    public func injectCoeffect(name: String) -> Interceptor {
        if let handler = registry.coeffectHandler(key: name) {
            return Interceptor(name: "coeffect: \(name)", before: { context in
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
        return Interceptor(name: "doEffects", before: nil, after: { context in
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

    public var debug: Interceptor {
        return debug { (str: String) in print(str) }
    }

    /// An interceptor that logs actions as they are processed and 
    /// indicates changes to the state made by the event handler
    public func debug(logFunction: @escaping LoggingFunction) -> Interceptor {
        return Interceptor(name: "debug", before: { context in
            if let action = context.coeffects["action"] {
                logFunction("\nHandling action: \(action):")
            }

            return context
        }, after: { context in
            let logAfter = { (str: String) in logFunction("  \(str)") }

            let action = context.coeffects["action"]
            let oldState = context.coeffects["state"] as? S
            let newState = context.effects["state"] as? S

            if let old = oldState, let new = newState {
                if old == new {
                    logAfter("No state changes made by event handler for action: \(action)")
                } else {
                    logAfter("Old State: \(old)")
                    logAfter("New State: \(new)")
                }
            } else {
                logAfter("No state changes made by event handler for action: \(action)")
            }

            logAfter("")

            return context
        })
    }

    // Wrapper Interceptors

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
}

/*
 Execute an interceptor chain starting from an action
 1. Injects the action into a Context
 2. Invokes the interceptors' before functions forwards
 3. Invokes the interceptors' after functions backwards
 */
func execute<A>(action: A, interceptors: [Interceptor]) {
    let cofx = ["action": action]
    var context = Context(coeffects: cofx, effects: [:], queue: Queue(items: interceptors), stack: Stack.empty())

    func invoke(interceptorFunction: (Interceptor) -> ((Context) -> Context)?) -> Context {
        var context = context
        while (context.queue.nonEmpty) {
            if let interceptor = context.queue.peek {
                context.queue.dequeue()
                context.stack.push(interceptor)
                if let newContext = interceptorFunction(interceptor)?(context) {
                    context = newContext
                }
            }
        }
        return context
    }

    // Invoke before functions
    context = invoke { $0.before }

    // Reverse by putting the stack back into the queue
    context.queue = Queue(items: context.stack.items.reversed())
    context.stack = Stack()

    // Invoke after functions
    context = invoke { $0.after }
}
