//
//  Date+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation

extension Optional where Wrapped == Date {
    
    var currentIfNil: Date {
        guard let date = self else { return Date() }
        return date
    }
}

extension Date {
    
    var interval: Int {
        return Int(self.timeIntervalSince1970)
    }
    
    var monthString: String {
        var currentYearComponent = DateComponents()
        currentYearComponent.year = Calendar.current.component(.year, from: Date())
        
        let format = Calendar.current.date(self, matchesComponents: currentYearComponent) ? "LLLL" : "LLLL yyyy"
        let formater = DateFormatter()
        formater.dateFormat = format
        return formater.string(from: self)
    }
    
    func asString(showTime: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = showTime ? .short : .none
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.string(from: self)
    }
}

extension DateFormatter {
  static let appFullDate: DateFormatter = {
    let df = DateFormatter()
    df.locale = .autoupdatingCurrent
    df.dateFormat = "dd MMMM yyyy"
    return df
  }()
}
