//
//  Effects.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation

extension Store {
    public func registerEffect(key: String, handler: @escaping EffectHandler) {
        registry.registerEffectHandler(key: key, handler: handler)
    }

    func registerBuiltinEffects() {
        // Update the store state based on the state in the effect map
        registerEffect(key: "state") { newState in
            if let newStateS = newState as? S {
                self.state.value = newStateS
            } else {
                fatalError("Failed to convert state to the store's state type")
            }
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
}