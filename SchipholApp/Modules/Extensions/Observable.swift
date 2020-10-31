//
//  Observable.swift
//  CopyPasteSwift
//
//  Created by abuzeid on 22.09.20.
//  Copyright © 2020 abuzeid. All rights reserved.
//

import Foundation

/// An Observable will give  any  subscriber  the most  recent element
/// and  everything that  is  emitted  by that  sequence after the  subscription  happened.
public final class Observable<T> {
    private var observers = [UUID: (T) -> Void]()
    private var _value: T {
        didSet {
            observers.values.forEach { $0(_value) }
        }
    }

    var value: T {
        return _value
    }

    init(_ value: T) {
        _value = value
    }

    @discardableResult
    func subscribe(on queue: DispatchQueue = .main, _ observer: @escaping ((T) -> Void)) -> UUID {
        let id = UUID()
        observers[id] = observer
        queue.async {
            observer(self.value)
        }
        return id
    }

    func unsubscribe(id: UUID) {
        observers.removeValue(forKey: id)
    }

    func next(_ newValue: T) {
        _value = newValue
    }
}
