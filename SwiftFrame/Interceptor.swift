//
//  Interceptor.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

/// The state passed through the interceptor chain.
public struct Context {
    /// A map from coeffect names to coeffect values, representing inputs to the event handler.
    public var coeffects: CoeffectMap

    /// A map from effect names to effect values, representing outputs of the event handler.
    public var effects: EffectMap

    /// A queue of interceptors that are yet to be processed.
    var queue: Queue<Interceptor>

    /// A stack of interceptors that have already been processed.
    var stack: Stack<Interceptor>
}

/// An `Interceptor` provides a pair of functions, `before` and `after`, which run before and after the
/// event handler for a given action, allowing for customisation of the coeffects provided to and the effects
/// received from an event handler.
public struct Interceptor {
    /// The name of this interceptor
    public let name: String

    /// The function to run before the event handler.
    public let before: ContextUpdater?

    /// The function to run after the event handler.
    public let after: ContextUpdater?

    /// A shorthand constructor for interceptors that only have a before function.
    public static func before(name: String, before: @escaping ContextUpdater) -> Interceptor {
        return Interceptor(name: name, before: before, after: nil)
    }

    /// A shorthand constructor for interceptors that only have an after function.
    public static func after(name: String, after: @escaping ContextUpdater) -> Interceptor {
        return Interceptor(name: name, before: nil, after: after)
    }
}

/**
    Execute an interceptor chain starting from an action
    1. Injects the action into a Context
    2. Invokes the interceptors' before functions forwards
    3. Invokes the interceptors' after functions backwards

    - parameter action: The action to inject into the context
    - parameter interceptors: The interceptors to execute
 */
func execute(action: Action, interceptors: [Interceptor]) {
    var context = Context(coeffects: ["action": action],
                          effects: [:],
                          queue: Queue(items: interceptors),
                          stack: Stack.empty())

    func invoke(interceptorFunction: (Interceptor) -> ContextUpdater?) -> Context {
        var context = context
        while context.queue.nonEmpty {
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
