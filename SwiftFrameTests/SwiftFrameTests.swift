//
//  SwiftFrameTests.swift
//  SwiftFrameTests
//
//  Created by Nicholas Hurden on 3/10/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import XCTest
@testable import SwiftFrame

class SwiftFrameTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTodoExample() {
        struct AddTodo: Action {
            static var name = "AddTodo"
            let name: String
        }

        struct AppState {
            var todos: [String] = []
        }

        let store = Store(initialState: AppState())
        store.registerEventState(actionClass: AddTodo.self) { (state, action) in
            var s = state ?? AppState()
            s.todos.append(action.name)
            return s
        }

        store.dispatch(action: AddTodo(name: "Do Stuff"))

        XCTAssert(store.state.todos.contains("Do Stuff"))
    }
}
