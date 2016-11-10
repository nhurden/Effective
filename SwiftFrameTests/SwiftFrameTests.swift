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
    func testTodoExample() {
        let store = Store(initialState: AppState())
        store.registerEventState(actionClass: AddTodo.self, interceptors: [store.debug]) { (state, action) in
            var s = state ?? AppState()
            s.todos.append(action.name)
            return s
        }

        store.registerEventState(actionClass: DoNothing.self, interceptors: [store.debug]) { (state, action) in
            state ?? AppState()
        }

        store.dispatch(action: AddTodo(name: "Do Stuff"))
        store.dispatch(action: DoNothing())
        store.dispatch(action: AddTodo(name: "Do Stuff"))

        XCTAssert(store.state.value.todos.contains("Do Stuff"))
        XCTAssertEqual(store.state.value.todos.count, 2)
    }
}
