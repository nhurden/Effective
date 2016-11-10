//
//  Coeffects.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation

extension Store {
    // Register a coeffect in the case where the name of the coeffect 
    // is the same as the desired key in the coeffect map
    public func registerCoeffect(key: String, value: @escaping @autoclosure () -> Any) {
        registerCoeffect(key: key) { coeffects in
            var cofx = coeffects
            cofx[key] = value()
            return cofx
        }
    }

    public func registerCoeffect(key: String, handler: @escaping CoeffectHandler) {
        registry.registerCoeffectHandler(key: key, handler: handler)
    }

    func registerBuiltinCoeffects() {
        // Add the store state to the coeffect map
        registerCoeffect(key: "state", value: self.state.value)
    }

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

    public func injectState() -> Interceptor {
        return injectCoeffect(name: "state")
    }
}