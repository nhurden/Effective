//
//  Core.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import RxSwift
import RxCocoa

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

/// A marker protocol for all actions.
/// `typeName` has a default implementation and does not need to be implemented.
public protocol Action {
    /// A string representing the type of this action
    var typeName: String { get }

    /// A string representing the type of this action
    static var typeName: String { get }
}

public extension Action {
    /// Proxies to the `typeName` at the type-level.
    var typeName: String {
        return type(of: self).typeName
    }

    /// Uses the name of the struct/class as the `typeName`.
    static var typeName: String {
        return String(describing: self)
    }
}

/// The core of this library, `Store` manages the current state and executes actions.
public class Store<S: Equatable> {
    let registry: Registry

    /// The current state of the store as an RxSwift `Variable`.
    private(set) var state: Variable<S>

    /// On observable of the current state of the store.
    public private(set) var stateObservable: Driver<S>

    /// Create a new store.
    /// - parameter initialState: The initial state of this store.
    public init(initialState: S) {
        registry = Registry()
        state = Variable(initialState)
        
        stateObservable = state.asDriver().distinctUntilChanged()

        registerBuiltinCoeffects()
        registerBuiltinEffects()
    }

    /**
     Dispatch an action for processing.
     - parameter action: The action to process
     */
    public func dispatch<A: Action>(_ action: A) {
        handleEvent(action: action)
    }
}
