//
//  BuiltinInterceptors.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

// Some of these interceptors depend on the store's registry and state type parameter
extension Store {
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

    /// An interceptor that runs the function given to update the state after the event handler is run.
    public func enrich<A: Action>(actionClass: A.Type, f: @escaping (S, A) -> S) -> Interceptor {
        return Interceptor.after(name: "enrich") { context in
            let (s, a) = self.extractStateAndAction(actionClass: actionClass, fromContext: context)
            
            var ctx = context
            ctx.effects["state"] = f(s, a)
            return ctx
        }
    }
    
    /// An interceptor that runs the function given for side effects after the event handler is run.
    public func after<A: Action>(actionClass: A.Type, f: @escaping (S, A) -> Void) -> Interceptor {
        return Interceptor.after(name: "after") { context in
            let (s, a) = self.extractStateAndAction(actionClass: actionClass, fromContext: context)
            f(s, a)
            return context
        }
    }

    private func extractStateAndAction<A: Action>(actionClass: A.Type, fromContext context: Context) -> (S, A) {
        guard let state = context.effects["state"] else {
            fatalError("Attempting to enrich without a state effect")
        }
        
        guard let action = context.coeffects["action"] else {
            fatalError("Attempting to enrich without an action coeffect")
        }
        
        guard let stateS = state as? S else {
            fatalError("State effect was not of the store's state type")
        }
        
        guard let actionA = action as? A else {
            fatalError("Action coeffect was not of the given action type")
        }

        return (stateS, actionA)
    }
}
