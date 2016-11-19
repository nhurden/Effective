//
//  Interceptor.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

public struct Context {
    var coeffects: CoeffectMap
    var effects: EffectMap

    var queue: Queue<Interceptor>
    var stack: Stack<Interceptor>
}

public struct Interceptor {
    let name: String
    let before: ContextUpdater?
    let after: ContextUpdater?

    static func before(name: String, before: @escaping ContextUpdater) -> Interceptor {
        return Interceptor(name: name, before: before, after: nil)
    }

    static func after(name: String, after: @escaping ContextUpdater) -> Interceptor {
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
