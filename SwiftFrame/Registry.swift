//
//  Registry.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

class Registry {
    fileprivate var eventHandlers: [String: [Interceptor]]
    fileprivate var effectHandlers: [String: EffectHandler]
    fileprivate var coeffectHandlers: [String: CoeffectHandler]

    init() {
        eventHandlers = [:]
        effectHandlers = [:]
        coeffectHandlers = [:]
    }

    func eventHandler(action: Action) -> [Interceptor]? {
        let key = action.typeName
        return eventHandlers[key]
    }

    func registerEventHandler(key: String, interceptors: [Interceptor]) {
        eventHandlers[key] = interceptors
    }

    func effectHandler(key: String) -> EffectHandler? {
        return effectHandlers[key]
    }

    func registerEffectHandler(key: String, handler: @escaping EffectHandler) {
        effectHandlers[key] = handler
    }

    func coeffectHandler(key: String) -> CoeffectHandler? {
        return coeffectHandlers[key]
    }

    func registerCoeffectHandler(key: String, handler: @escaping CoeffectHandler) {
        coeffectHandlers[key] = handler
    }
}
