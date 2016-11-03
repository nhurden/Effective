//
//  Coeffects.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/11/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation

extension Store {
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
