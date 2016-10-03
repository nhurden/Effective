//
//  Registry.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation

class Registry<A: CaseName, S> {
    fileprivate var eventHandlers: [String : [Interceptor]]
    fileprivate var effectHandlers: [String : EffectHandler]
    fileprivate var coeffectHandlers: [String : CoeffectHandler]
    fileprivate var subscriptionHandlers: [String : [Interceptor]] // FIXME

    init() {
        eventHandlers = [:]
        effectHandlers = [:]
        coeffectHandlers = [:]
        subscriptionHandlers = [:]
    }

    func eventHandler(action: A) -> [Interceptor]? {
        return eventHandlers[action.nameForCase()]
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

    func subscriptionHandler(key: String) -> [Interceptor]? {
        return subscriptionHandlers[key]
    }

    func registerSubscriptionHandler(key: String, handler: [Interceptor]) {
        subscriptionHandlers[key] = handler
    }
}
