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
}
