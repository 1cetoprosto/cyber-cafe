//
//  NumberFormatter+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation

extension NumberFormatter {
    
    static var decimal: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.groupingSeparator = ""
        return numberFormatter
    }
    
    static var currencyInteger: NumberFormatter {
        let formater = NumberFormatter()
        formater.numberStyle = .currency
        formater.minimumFractionDigits = 2
        formater.maximumFractionDigits = 2
        formater.currencyDecimalSeparator = ","
        formater.currencyGroupingSeparator = " "
        // TODO: перенести RequestManager
        formater.currencySymbol = "$" //RequestManager.shared.settings?.currencySymbol ?? "$"
        return formater
    }
    
    static var percent: NumberFormatter {
        let format = NumberFormatter()
        format.numberStyle = .percent
        format.maximumFractionDigits = 2
        format.minimumFractionDigits = 0
        format.groupingSize = 3
        format.locale = Locale.autoupdatingCurrent
        format.multiplier = 1
        return format
    }
    
    func string(_ value: Int) -> String {
        return string(from: NSNumber(value: value))!
    }
    
    func string(_ value: Double) -> String {
        return string(from: NSNumber(value: value))!
    }
}

