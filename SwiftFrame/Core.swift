//
//  Core.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 30/09/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import RxSwift
import RxCocoa

/// A string keyed map
public typealias StringMap = [String: Any]

/// A map of effects, used in the context
public typealias EffectMap = StringMap

/// A map of coeffects, used in the context
public typealias CoeffectMap = StringMap

/// A function that updates the context
public typealias ContextUpdater = (Context) -> Context

/// A reducer function that is specialised to one specific `Action`
/// and updates the state without performing effects
public typealias EventHandlerState<A, S> = (S, A) -> S

/// A reducer function that is specialised to one specific `Action` and performs effects
public typealias EventHandlerEffects<A> = (CoeffectMap, A) -> EffectMap

/// A reducer function that is specialised to one specific `Action`
/// and performs arbitrary context changes
public typealias EventHandlerContext = ContextUpdater

/// A function that handles effects by being passed the value stored in the effects map
public typealias EffectHandler = (Any) -> Void

/// A function that injects coeffects by adding to the coeffect map
public typealias CoeffectHandler = (CoeffectMap) -> CoeffectMap

/// A function that receives logging output
public typealias LoggingFunction = (String) -> Void

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

    /// Observe a projection of the store by applying `keyPath`
    /// - parameter keyPath: The keypath to apply to the state
    /// - parameter comparer: A function to test whether two elements of the projected type are equal for the purposes of distinctUntilChanged
    public func observe<T>(keyPath: KeyPath<S, T>, comparer: @escaping (T, T) -> Bool) -> Driver<T> {
        return stateObservable.map { $0[keyPath: keyPath] }.distinctUntilChanged(comparer)
    }

    /**
     Dispatch an action for processing.
     - parameter action: The action to process
     */
    public func dispatch<A: Action>(_ action: A) {
        handleEvent(action: action)
    }
}
