//
//  InterceptorTests.swift
//  Effective
//
//  Created by Nicholas Hurden on 3/1/18.
//

import XCTest
@testable import Effective

class InterceptorTests: XCTestCase {
    struct DoNothing: Action {}
    struct Increment: Action {}

    func testDebugInterceptor() {
        let store = Store(initialState: 1)
        var messages: [String] = []
        let debug = store.debug(logFunction: { s in
            messages.append(s)
        })

        store.registerEventState(actionClass: DoNothing.self, interceptors: [debug]) { s, _ in s }
        store.registerEventState(actionClass: Increment.self, interceptors: [debug]) { s, _ in s + 1 }

        store.dispatch(DoNothing())
        store.dispatch(Increment())

        XCTAssertEqual(messages[0], "\nHandling action: DoNothing():")
        XCTAssertEqual(messages[1], "  No state changes made by event handler for action: DoNothing()")
        XCTAssertEqual(messages[2], "  ")

        XCTAssertEqual(messages[3], "\nHandling action: Increment():")
        XCTAssertEqual(messages[4], "  Old State: 1")
        XCTAssertEqual(messages[5], "  New State: 2")
        XCTAssertEqual(messages[6], "  ")
    }
}
