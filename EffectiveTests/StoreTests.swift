//
//  StoreTests.swift
//  StoreTests
//
//  Created by Nicholas Hurden on 3/10/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

import XCTest
@testable import Effective

import RxSwift
import RxCocoa
import RxTest

// Todos

struct AddTodo: Action {
    let name: String
}

struct AddTodos: Action {
    let name: String
}

struct AddTodoAndIncrement: Action {
    let name: String
}

struct PreAddTodo: Action {
    let name: String
}

struct AddTodoLater: Action {
    let name: String
    let delay: TimeInterval
}

struct DoNothing: Action {}
struct Increment: Action {}

struct AppState {
    var todos: [String] = []
}
extension AppState: Equatable {}

func == (lhs: AppState, rhs: AppState) -> Bool {
    return lhs.todos == rhs.todos
}

func todoStore() -> Store<AppState> {
    let store = Store(initialState: AppState())

    store.registerEventState(actionClass: DoNothing.self) { state, _ in
        state
    }

    store.registerEventState(actionClass: AddTodo.self) { state, action in
        var s = state
        s.todos.append(action.name)
        return s
    }

    return store
}

// Counter

struct CounterState {
    var count: Int = 0
}
extension CounterState: Equatable {}

func == (lhs: CounterState, rhs: CounterState) -> Bool {
    return lhs.count == rhs.count
}

class StoreTests: XCTestCase {
    func testTodoSimple() {
        let store = todoStore()

        store.dispatch(AddTodo(name: "Do Stuff"))
        store.dispatch(DoNothing())
        store.dispatch(AddTodo(name: "Do Stuff"))

        XCTAssert(store.state.value.todos.contains("Do Stuff"))
        XCTAssertEqual(store.state.value.todos.count, 2)
    }

    enum CounterEffect {
        case increment
    }

    func testTodoEffects() {
        let store = todoStore()

        store.registerEventEffects(actionClass: AddTodoAndIncrement.self) { coeffects, action in
            let state = coeffects["state"] as? AppState
            var newState = state ?? AppState()
            newState.todos.append(action.name)

            return [ "counter": CounterEffect.increment,
                     "state": newState ]
        }

        var actionsAdded = 0
        store.registerEffect(key: "counter") { action in
            if let action = action as? CounterEffect {
                switch action {
                case .increment:
                    actionsAdded += 1
                }
            }
        }

        store.dispatch(AddTodoAndIncrement(name: "First"))
        store.dispatch(AddTodoAndIncrement(name: "Second"))
        store.dispatch(AddTodoAndIncrement(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))
        XCTAssertEqual(store.state.value.todos.count, 3)
        XCTAssertEqual(actionsAdded, 3)
    }

    // An alternate way to do the above counter example using the `after` interceptor
    // instead of explicit effects and a new action type
    func testTodoAfterEffects() {
        let store = todoStore()

        var actionsAdded = 0
        let inc = store.after(actionClass: AddTodo.self) { _, _ in
            actionsAdded += 1
        }

        store.registerEventState(actionClass: AddTodo.self, interceptors: [inc]) { state, action in
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

        let dedup = store.enrich(actionClass: AddTodo.self) { state, _ in
            let newTodos = Array(Set(state.todos))
            return AppState(todos: newTodos)
        }

        store.registerEventState(actionClass: AddTodo.self, interceptors: [dedup]) { state, action in
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

        // Just dispatches AddTodo
        store.registerEventEffects(actionClass: PreAddTodo.self) { _, action in
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

        store.registerEventEffects(actionClass: AddTodoLater.self) { _, action in
            return [ "dispatchAfter": DispatchAfter(delaySeconds: action.delay,
                                                    action: AddTodo(name: action.name))]
        }

        store.dispatch(AddTodoLater(name: "First", delay: 0.1))
        store.dispatch(AddTodoLater(name: "Second", delay: 0.2))
        store.dispatch(AddTodoLater(name: "Third", delay: 0.3))

        XCTAssertEqual(store.state.value.todos.count, 0)

        let e = expectation(description: "Store is updated later")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssert(store.state.value.todos.contains("First"))
            XCTAssert(store.state.value.todos.contains("Second"))
            XCTAssert(store.state.value.todos.contains("Third"))
            XCTAssertEqual(store.state.value.todos.count, 3)
            e.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testRedispatchMultiple() {
        let store = todoStore()

        // Just dispatches AddTodo twice
        store.registerEventEffects(actionClass: AddTodos.self) { _, action in
            let actions = [AddTodo(name: action.name), AddTodo(name: action.name.uppercased())]
            return [ "dispatchMultiple": actions]
        }

        store.dispatch(AddTodos(name: "First"))
        store.dispatch(AddTodos(name: "Second"))
        store.dispatch(AddTodos(name: "Third"))

        XCTAssert(store.state.value.todos.contains("First"))
        XCTAssert(store.state.value.todos.contains("Second"))
        XCTAssert(store.state.value.todos.contains("Third"))

        XCTAssert(store.state.value.todos.contains("FIRST"))
        XCTAssert(store.state.value.todos.contains("SECOND"))
        XCTAssert(store.state.value.todos.contains("THIRD"))

        XCTAssertEqual(store.state.value.todos.count, 6)
    }

    // When equatable, there is no need to supply a comparer function
    func testObservingKeyPathsWithEquatable() {
        // Store Setup
        let store = Store(initialState: CounterState())

        store.registerEventState(actionClass: Increment.self) { state, _ in
            var s = state
            s.count += 1
            return s
        }

        // Test Setup
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver(Int.self)
        let disposeBag = DisposeBag()

        let count: Driver<Int> = store.observe(keyPath: \.count)
        let countExpectation = expectation(description: "count of 3")

        count.drive(onNext: { c in
            if c == 3 {
                countExpectation.fulfill()
            }
        }).disposed(by: disposeBag)

        count.drive(observer)
            .disposed(by: disposeBag)

        // Tests
        store.dispatch(Increment())
        store.dispatch(Increment())
        store.dispatch(Increment())

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(observer.events.count, 4) // initial + 3 changes
            XCTAssertEqual(observer.events[0].value.element!, 0)
            XCTAssertEqual(observer.events[1].value.element!, 1)
            XCTAssertEqual(observer.events[2].value.element!, 2)
            XCTAssertEqual(observer.events[3].value.element!, 3)
        }
    }

    // Array is a special case because it is not Equatable
    func testObservingKeyPathsWithArrayT() {
        // Store Setup
        let store = todoStore()

        // Test Setup
        let scheduler = TestScheduler(initialClock: 0)
        let observer = scheduler.createObserver([String].self)
        let disposeBag = DisposeBag()

        // Replaces: let todos = store.stateObservable.asObservable().map { $0.todos }.distinctUntilChanged(==)
        let todos: Driver<[String]> = store.observe(keyPath: \.todos, comparer: ==)
        let threeTodosExpectation = expectation(description: "Three todos")

        todos.drive(onNext: { ts in
            if ts.count == 3 {
                threeTodosExpectation.fulfill()
            }
        }).disposed(by: disposeBag)

        todos.drive(observer)
            .disposed(by: disposeBag)

        // Tests
        store.dispatch(AddTodo(name: "First"))
        store.dispatch(AddTodo(name: "Second"))
        store.dispatch(AddTodo(name: "Third"))

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(observer.events.count, 4) // initial + 3 changes
            XCTAssertEqual(observer.events[0].value.element!, [])
            XCTAssertEqual(observer.events[1].value.element!, ["First"])
            XCTAssertEqual(observer.events[2].value.element!, ["First", "Second"])
            XCTAssertEqual(observer.events[3].value.element!, ["First", "Second", "Third"])
        }
    }

    func testCoeffectInjection() {
        let store = todoStore()

        store.registerCoeffect(key: "time", value: NSDate(timeIntervalSince1970: 0))

        let injectTime = store.injectCoeffect(name: "time")

        store.registerEventEffects(actionClass: AddTodo.self, interceptors: [injectTime]) { coeffects, action in
            let state = coeffects["state"] as? AppState
            var newState = state ?? AppState()

            let time = coeffects["time"] as? NSDate
            let todoName = String(describing: time) + " " + action.name
            newState.todos.append(todoName)

            return [ "state": newState ]
        }

        store.dispatch(AddTodo(name: "First"))
        store.dispatch(AddTodo(name: "Second"))
        store.dispatch(AddTodo(name: "Third"))

        let todos = store.state.value.todos
        let prefix = String(describing: NSDate(timeIntervalSince1970: 0) as NSDate?)
        XCTAssertEqual(todos[0], prefix + " First")
        XCTAssertEqual(todos[1], prefix + " Second")
        XCTAssertEqual(todos[2], prefix + " Third")
    }
}
