//
//  Queue.swift
//  SwiftFrame
//
//  Created by Nicholas Hurden on 3/10/2016.
//  Copyright © 2016 Nicholas Hurden. All rights reserved.
//

struct Queue<T> {
    var items: [T]

    static func empty() -> Queue {
        return Queue(items: [])
    }

    mutating func enqueue(_ item: T) {
        items.append(item)
    }

    @discardableResult
    mutating func dequeue() -> T {
        return items.removeFirst()
    }

    var isEmpty: Bool { return items.isEmpty }
    var nonEmpty: Bool { return !isEmpty }

    var peek: T? { return items.first }
}
