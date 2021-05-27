//
//  Synchronized.swift
//  OpenIM
//
//  Created by Snow on 2021/5/19.
//

import Foundation

public class Synchronized<T> {
    private var _value: T
    
    private let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".synchronized", qos: .default, attributes: .concurrent)
    
    public init(_ value: T) {
        _value = value
    }
    
    public var value: T {
        get { reader { $0 } }
        set { writer { $0 = newValue } }
    }
    
    public func reader<U>(_ block: (_ value: T) throws -> U) rethrows -> U {
        return try queue.sync { try block(_value) }
    }
    
    func writer(_ block: @escaping ( _ value: inout T) -> Void) {
        queue.async(flags: .barrier) {
            block(&self._value)
        }
    }
}
