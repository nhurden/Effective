//
//  Core.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import RxSwift

public typealias StringMap = [String: Any]
public typealias EffectMap = StringMap
public typealias CoeffectMap = StringMap

public typealias ContextUpdater = (Context) -> Context

public typealias EventHandlerState<A, S> = (S, A) -> S
public typealias EventHandlerEffects<A> = (CoeffectMap, A) -> EffectMap
public typealias EventHandlerContext = ContextUpdater

public typealias EffectHandler = (Any) -> ()
public typealias CoeffectHandler = (CoeffectMap) -> CoeffectMap

public typealias LoggingFunction = (String) -> ()

public protocol Action {
    var typeName: String { get }
    static var typeName: String { get }
}

public extension Action {
    var typeName: String {
        return type(of: self).typeName
    }

    static var typeName: String {
        return String(describing: self)
    }
}

public class Store<S: Equatable> {
    let registry: Registry
    public private(set) var state: Variable<S>
    public private(set) var stateObservable: Observable<S>

    public init(initialState: S) {
        registry = Registry()
        state = Variable(initialState)
        stateObservable = state.asObservable().distinctUntilChanged()

        registerBuiltinCoeffects()
        registerBuiltinEffects()
    }

    public func dispatch<A: Action>(_ action: A) {
        handleEvent(action: action)
    }
}
