//
//  Interceptor.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation

public struct Interceptor {
    let name: String
    let before: ((Context) -> Context)?
    let after: ((Context) -> Context)?
}

// Some of these interceptors depend on the store's registry and state type parameter
extension Store {
    // MARK: Basic Interceptors
    
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
    
    // MARK: User Interceptors
    
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
