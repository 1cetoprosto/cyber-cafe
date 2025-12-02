//
//  String+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation

extension String {
    
    enum RegularExpressions: String {
        case phone = "^\\s*(?:\\+?(\\d{1,3}))?([-. (]*(\\d{3})[-. )]*)?((\\d{3})[-. ]*(\\d{2,4})(?:[-.x ]*(\\d+))?)\\s*$"
        case email = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    }
    
    func isValid(regex: RegularExpressions) -> Bool {
        return isValid(regex: regex.rawValue)
    }
    
    func isValid(regex: String) -> Bool {
        let matches = range(of: regex, options: .regularExpression)
        return matches != nil
    }
    
    func onlyDigits() -> String {
        let filtredUnicodeScalars = unicodeScalars.filter{CharacterSet.decimalDigits.contains($0)}
        return String(String.UnicodeScalarView(filtredUnicodeScalars))
    }

// TODO: розібратися як можна подзвонити, якщо дійсно потрібен такий функціонал
//    func makeACall() {
//        if isValid(regex: .phone) {
//            if let url = URL(string: "tel://\(self.onlyDigits())"), UIApplication.shared.canOpenURL(url) {
//                if #available(iOS 10, *) {
//                    UIApplication.shared.open(url)
//                } else {
//                    UIApplication.shared.openURL(url)
//                }
//            }
//        }
//    }

    var nilIfEmpty: String? {
        if self.isEmpty { return nil }
        return self
    }
    
    var url: URL? {
        return URL(string: self)
    }
    
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var intOrZero: Int {
        return Int(self) ?? 0
    }
    
    var double: Double? {
        if let value = Double(self) { return value }
        let normalized = self.replacingOccurrences(of: ",", with: ".")
        let allowed = CharacterSet(charactersIn: "0123456789.-")
        let filtered = normalized.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
        return Double(filtered)
    }
    
    var doubleOrZero: Double {
        return self.double ?? 0.0
    }
    
    var isImage: Bool {
        return contains(FileExtensions.jpeg) || contains("." + FileExtensions.jpeg) || contains(".png")
    }
    
    var isAudio: Bool {
        return contains(".caf") || contains(".mp3") || contains(".3gp") || contains(".m4a")
    }
    
    func containsCaseIgnore(_ string: String?) -> Bool {
        guard let value = string else { return false }
        return self.lowercased().contains(value.lowercased())
    }
}

extension Optional where Wrapped == String {
    
    var emptyIfNil: String {
        guard let self = self else { return "" }
        return self
    }
    
    func containsCaseIgnore(_ string: String?) -> Bool {
        guard let self = self else { return false }
        return self.containsCaseIgnore(string)
    }
}

extension CustomStringConvertible {
    
    var description : String {
        var description: String = "\n*** ⚠️ \(type(of: self)) ⚠️ ***:\n"
        let selfMirror = Mirror(reflecting: self)
        for child in selfMirror.children {
            if let propertyName = child.label {
                description += "\(propertyName): \(child.value)\n"
            }
        }
        description = String(description.dropLast(2)) + ".\n"
        return description
    }
}
