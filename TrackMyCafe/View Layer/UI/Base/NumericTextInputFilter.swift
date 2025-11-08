//
//  NumericTextInputFilter.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 07.11.2025.
//

import Foundation

struct NumericTextInputFilter {
  let decimalSeparator: String
  let maxFractionDigits: Int

  init(maxFractionDigits: Int = 2, locale: Locale = .current) {
    let formatter = NumberFormatter()
    formatter.locale = locale
    self.decimalSeparator = formatter.decimalSeparator ?? ","
    self.maxFractionDigits = maxFractionDigits
  }

  func sanitize(_ input: String) -> String {
    var text = input

    // Normalize known separators to current locale
    text = text.replacingOccurrences(of: ".", with: decimalSeparator)
      .replacingOccurrences(of: ",", with: decimalSeparator)

    // Keep digits and one separator only
    let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: decimalSeparator))
    text = text.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()

    // Only one separator
    let parts = text.components(separatedBy: decimalSeparator)
    if parts.count > 2 {
      // Merge extra separators into last part
      text = parts[0] + decimalSeparator + parts.dropFirst().joined()
    }

    // If starts with separator, prefix zero
    if text.hasPrefix(decimalSeparator) {
      text = "0" + decimalSeparator + text.dropFirst()
    }

    // Limit fraction digits
    if let sepRange = text.range(of: decimalSeparator) {
      let fractional = text[sepRange.upperBound...]
      if fractional.count > maxFractionDigits {
        let limited = fractional.prefix(maxFractionDigits)
        text = String(text[..<sepRange.upperBound]) + String(limited)
      }
    }

    // Remove redundant leading zeros unless decimal like 0,xx
    if !text.isEmpty, text.hasPrefix("0") {
      if text.contains(decimalSeparator) {
        // allow single leading zero (e.g., 0,12)
        // but compress multiple zeros before separator (e.g., 000,12 -> 0,12)
        let parts = text.components(separatedBy: decimalSeparator)
        let integer = parts[0]
        let trimmedInt = integer.drop { $0 == "0" }
        let safeInt = trimmedInt.isEmpty ? "0" : String(trimmedInt)
        text = safeInt + decimalSeparator + parts.dropFirst().joined(separator: decimalSeparator)
      } else {
        // integer case: remove all leading zeros
        let trimmed = text.drop { $0 == "0" }
        text = trimmed.isEmpty ? "0" : String(trimmed)
      }
    }

    return text
  }
}