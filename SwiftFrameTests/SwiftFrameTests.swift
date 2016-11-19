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
    let name: String
}

struct PreAddTodo: Action {
    let name: String
}

struct DoNothing: Action {}

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
            state
        }
        
        return store
    }
    
    func testTodoSimple() {
        let store = todoStore()

        store.registerEventState(actionClass: AddTodo.self) { (state, action) in
            var s = state
            s.todos.append(action.name)
            return s
        }

        store.dispatch(AddTodo(name: "Do Stuff"))
        store.dispatch(DoNothing())
        store.dispatch(AddTodo(name: "Do Stuff"))

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

        store.dispatch(AddTodo(name: "First"))
        store.dispatch(AddTodo(name: "Second"))
        store.dispatch(AddTodo(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))
        XCTAssertEqual(store.state.value.todos.count, 3)
        XCTAssertEqual(actionsAdded, 3)
    }

    // An alternate way to do the above counter example using the `after` interceptor instead of explicit effects
    func testTodoAfterEffects() {
        let store = todoStore()

        var actionsAdded = 0
        let inc = store.after(actionClass: AddTodo.self) { state, action in
            actionsAdded += 1
        }

        store.registerEventState(actionClass: AddTodo.self, interceptors: [inc]) { (state, action) in
            var s = state
            s.todos.append(action.name)
            return s
        }

        store.dispatch(AddTodo(name: "First"))
        store.dispatch(AddTodo(name: "Second"))
        store.dispatch(AddTodo(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))
        XCTAssertEqual(store.state.value.todos.count, 3)
        XCTAssertEqual(actionsAdded, 3)
    }

    func testTodosDeduplicate() {
        let store = todoStore()

        let dedup = store.enrich(actionClass: AddTodo.self) { state, action in
            let newTodos = Array(Set(state.todos))
            return AppState(todos: newTodos)
        }
        
        store.registerEventState(actionClass: AddTodo.self, interceptors: [dedup]) { (state, action) in
            var s = state
            s.todos.append(action.name)
            return s
        }

        store.dispatch(AddTodo(name: "First"))
        store.dispatch(AddTodo(name: "Second"))
        store.dispatch(AddTodo(name: "Third"))
        store.dispatch(AddTodo(name: "First"))
        store.dispatch(AddTodo(name: "Second"))
        store.dispatch(AddTodo(name: "Third"))
        store.dispatch(AddTodo(name: "First"))
        store.dispatch(AddTodo(name: "Second"))
        store.dispatch(AddTodo(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))
        XCTAssertEqual(store.state.value.todos.count, 3)
    }

    func testRedispatch() {
        let store = todoStore()

        store.registerEventState(actionClass: AddTodo.self) { state, action in
            var s = state
            s.todos.append(action.name)
            return s
        }

        // Just dispatches AddTodo
        store.registerEventEffects(actionClass: PreAddTodo.self) { coeffects, action in
            return [ "dispatch": AddTodo(name: action.name)]
        }

        store.dispatch(PreAddTodo(name: "First"))
        store.dispatch(PreAddTodo(name: "Second"))
        store.dispatch(PreAddTodo(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))
        XCTAssertEqual(store.state.value.todos.count, 3)
    }

    func testRedispatchAfter() {
        let store = todoStore()

        store.registerEventState(actionClass: AddTodo.self) { state, action in
            var s = state
            s.todos.append(action.name)
            return s
        }

        // Just dispatches AddTodo after a second
        store.registerEventEffects(actionClass: PreAddTodo.self) { coeffects, action in
            return [ "dispatchAfter": DispatchAfter(delaySeconds: 1.0,
                                                    action: AddTodo(name: action.name))]
        }

        store.dispatch(PreAddTodo(name: "First"))
        store.dispatch(PreAddTodo(name: "Second"))
        store.dispatch(PreAddTodo(name: "Third"))

        XCTAssertEqual(store.state.value.todos.count, 0)

        let e = expectation(description: "Store is updated later")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssert(store.state.value.todos.contains("First"))
            XCTAssert(store.state.value.todos.contains("Second"))
            XCTAssert(store.state.value.todos.contains("Third"))
            XCTAssertEqual(store.state.value.todos.count, 3)
            e.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testRedispatchMultiple() {
        let store = todoStore()

        store.registerEventState(actionClass: AddTodo.self) { state, action in
            var s = state
            s.todos.append(action.name)
            return s
        }

        // Just dispatches AddTodo twice
        store.registerEventEffects(actionClass: PreAddTodo.self) { coeffects, action in
            let actions = [AddTodo(name: action.name), AddTodo(name: action.name.uppercased())]
            return [ "dispatchMultiple": actions]
        }

        store.dispatch(PreAddTodo(name: "First"))
        store.dispatch(PreAddTodo(name: "Second"))
        store.dispatch(PreAddTodo(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))

        XCTAssert(store.state.value.todos.contains("FIRST"))
        XCTAssert(store.state.value.todos.contains("SECOND"))
        XCTAssert(store.state.value.todos.contains("THIRD"))

        XCTAssertEqual(store.state.value.todos.count, 6)
    }
}
