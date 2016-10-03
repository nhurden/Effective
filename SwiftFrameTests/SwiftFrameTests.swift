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

        store.dispatch(action: AddTodo(name: "Do Stuff"))

        XCTAssert(store.state.todos.contains("Do Stuff"))
    }
}
