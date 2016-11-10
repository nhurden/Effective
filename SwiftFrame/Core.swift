//
//  Core.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import Foundation
import RxSwift

public typealias StringMap = [String: Any]
public typealias EffectMap = StringMap
public typealias CoeffectMap = StringMap

public typealias ContextUpdater = (Context) -> Context

public typealias EventHandlerState<A, S> = (S?, A) -> S
public typealias EventHandlerEffects<A> = (CoeffectMap, A) -> EffectMap
public typealias EventHandlerContext = ContextUpdater

public typealias EffectHandler = (Any) -> ()
public typealias CoeffectHandler = (CoeffectMap) -> CoeffectMap

public typealias LoggingFunction = (String) -> ()

public protocol Action {
    static var name: String { get }
}

public class Store<S: Equatable> {
    let registry: Registry
    private(set) var state: Variable<S>
    private(set) var stateObservable: Observable<S>

    public init(initialState: S) {
        registry = Registry()
        state = Variable(initialState)
        stateObservable = state.asObservable().distinctUntilChanged()

        registerBuiltinCoeffects()
        registerBuiltinEffects()
    }

    public func dispatch<A: Action>(action: A) {
        handleEvent(action: action)
    }
}
