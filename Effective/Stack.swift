//
//  Stack.swift
//  Effective
//
//  Created by Nicholas Hurden on 3/10/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

struct Stack<T> {
    var items = [T]()

    static func empty() -> Stack {
        return Stack(items: [])
    }

    mutating func push(_ item: T) {
        items.append(item)
    }

    mutating func pop() -> T {
        return items.removeLast()
    }
}
