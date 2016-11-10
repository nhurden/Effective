//
//  SwiftFrameTests.swift
//  SwiftFrameTests
//
//  Created by Nicholas Hurden on 3/10/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import XCTest
@testable import SwiftFrame

// Todos

struct AddTodo: Action {
    static var name = "AddTodo"
    let name: String
}

struct DoNothing: Action {
    static var name = "DoNothing"
}

struct AppState {
    var todos: [String] = []
}
extension AppState: Equatable {}

func ==(lhs: AppState, rhs: AppState) -> Bool {
    return lhs.todos == rhs.todos
}

class SwiftFrameTests: XCTestCase {
    func todoStore() -> Store<AppState> {
        let store = Store(initialState: AppState())

        store.registerEventState(actionClass: DoNothing.self) { (state, action) in
            state ?? AppState()
        }
        
        return store
    }
    
    func testTodoSimple() {
        let store = todoStore()

        store.registerEventState(actionClass: AddTodo.self) { (state, action) in
            var s = state ?? AppState()
            s.todos.append(action.name)
            return s
        }

        store.dispatch(action: AddTodo(name: "Do Stuff"))
        store.dispatch(action: DoNothing())
        store.dispatch(action: AddTodo(name: "Do Stuff"))

        XCTAssert(store.state.value.todos.contains("Do Stuff"))
        XCTAssertEqual(store.state.value.todos.count, 2)
    }

    func testTodoEffects() {
        let store = todoStore()

        enum CounterAction {
            case increment
        }

        store.registerEventEffects(actionClass: AddTodo.self) { (coeffects, action) in
            let state = coeffects["state"] as? AppState
            var newState = state ?? AppState()
            newState.todos.append(action.name)

            return [ "counter": CounterAction.increment,
                     "state": newState ]
        }

        var actionsAdded = 0
        store.registerEffect(key: "counter") { action in
            if let action = action as? CounterAction {
                switch action {
                case .increment:
                    actionsAdded += 1
                }
            }
        }

        store.dispatch(action: AddTodo(name: "First"))
        store.dispatch(action: AddTodo(name: "Second"))
        store.dispatch(action: AddTodo(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))
        XCTAssertEqual(store.state.value.todos.count, 3)
        XCTAssertEqual(actionsAdded, 3)
    }
}
