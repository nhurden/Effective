//
//  Coeffects.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

extension Store {
    // MARK: Coeffect Handlers

    /// Register a coeffect in the case where the name of the coeffect
    /// is the same as the desired key in the coeffect map
    public func registerCoeffect(key: String, value: @escaping @autoclosure () -> Any) {
        registerCoeffect(key: key) { coeffects in
            var cofx = coeffects
            cofx[key] = value()
            return cofx
        }
    }

    /// Register a coeffect handler for the given key.
    /// The given key will be used to lookup the coeffect when it is injected with `injectCoeffect`.
    public func registerCoeffect(key: String, handler: @escaping CoeffectHandler) {
        registry.registerCoeffectHandler(key: key, handler: handler)
    }

    /// Register the built-in coeffects. Currently this only includes the `state` coeffect.
    func registerBuiltinCoeffects() {
        // Add the store state to the coeffect map
        registerCoeffect(key: "state", value: self.state.value)
    }

    /// Lookup a coeffect handler and wrap it in a before Interceptor
    public func injectCoeffect(name: String) -> Interceptor {
        if let handler = registry.coeffectHandler(key: name) {
            return Interceptor.before(name: "coeffect: \(name)") { context in
                var ctx = context
                ctx.coeffects = handler(context.coeffects)
                return ctx
            }
        } else {
            fatalError("Could not find a coeffect handler for key \(name)")
        }
    }

    /// An interceptor that injects the state coeffect.
    public func injectState() -> Interceptor {
        return injectCoeffect(name: "state")
    }
}
