//
//  UITextField+NumericInput.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 07.11.2025.
//

import UIKit
import ObjectiveC

private var _numericFilterKey: UInt8 = 0

extension UITextField {
  private var _numericFilter: NumericTextInputFilter? {
    get { objc_getAssociatedObject(self, &_numericFilterKey) as? NumericTextInputFilter }
    set { objc_setAssociatedObject(self, &_numericFilterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  public func enableNumericInput(maxFractionDigits: Int = 2) {
    _numericFilter = NumericTextInputFilter(maxFractionDigits: maxFractionDigits)
    keyboardType = .decimalPad
    addTarget(self, action: #selector(_numericEditingChanged), for: .editingChanged)
  }

  @objc private func _numericEditingChanged() {
    guard let filter = _numericFilter else { return }
    let original = text ?? ""
    let sanitized = filter.sanitize(original)
    if sanitized != original { text = sanitized }
  }
}