//
//  Types+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation

protocol StringConvertible {
    
    var string: String { get }
}

extension StringConvertible {
    
    var string: String {
        return "\(self)"
    }
}

extension Int: StringConvertible {}
extension Float: StringConvertible {}
extension Double: StringConvertible {}

extension Optional {
    
    var string: String? {
        guard let self = self else { return nil }
        return "\(self)"
    }
}

extension Double {
    
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(self))
    }
    
    var oneIfZero: Double {
        return self == 0 ? 1.0 : self
    }
    
    var nilIfZero: Double? {
        return self == 0 ? nil : self
    }
    
    var currency: String {
        return NumberFormatter.currencyInteger.string(from: NSNumber(value: self)) ?? ""
    }
    
    var int: Int {
        return Int(self)
    }
    
    func round(to fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
    
    var decimalFormat: String {
        return NumberFormatter.decimal.string(self)
    }

    var quantityFormat: String {
        return NumberFormatter.quantity.string(self)
    }
}

extension Int {
    
    var currency: String {
        return NumberFormatter.currencyInteger.string(from: NSNumber(value: self)) ?? ""
    }
    
    var percent: String {
        return "\(self) %"
    }
    
    var double: Double {
        return Double(self)
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension CGRect {
    var minEdge: CGFloat {
        return min(width, height)
    }
}

extension Optional where Wrapped == Double {
    
    var zeroIfNil: Double {
        return self ?? 0.0
    }
}

extension Optional {
    
    func ifNotEmpty<I: Any>(_ value: I) -> I? {
        guard let _ = self else { return nil }
        return value
    }
}

extension Bool {
    func `let`<I: Any>(_ value: I) -> I? {
        guard self else { return nil }
        return value
    }
}
