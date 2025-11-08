//
//  InputContainerView.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 30.12.2024.
//

import TinyConstraints
import UIKit

// MARK: - Input Type Enum

enum InputType {
  case text(keyboardType: UIKeyboardType = .default)
  case date(mode: UIDatePicker.Mode = .date)
  case picker(data: [String])
  case toggle(isOn: Bool = false)
}

final class InputContainerView: UIView {

  // MARK: - UI Elements

  private lazy var containerView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.TableView.cellBackground
    view.layer.cornerRadius = 12
    return view
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    label.textColor = UIColor.Main.text
    return label
  }()

  // Input Elements
  private lazy var textField: UITextField = {
    let textField = UITextField()
    textField.font = UIFont.systemFont(ofSize: 20)
    textField.textColor = UIColor.Main.text
    textField.backgroundColor = .clear
    textField.borderStyle = .none
    textField.returnKeyType = .next
    return textField
  }()

  private lazy var datePicker: UIDatePicker = {
    let picker = UIDatePicker()
    picker.preferredDatePickerStyle = .compact
    picker.datePickerMode = .date
    return picker
  }()

  private lazy var pickerView: UIPickerView = {
    let picker = UIPickerView()
    return picker
  }()

  private lazy var switchControl: UISwitch = {
    let switchControl = UISwitch()
    switchControl.onTintColor = UIColor.Main.accent
    return switchControl
  }()

  // MARK: - Properties

  private var inputType: InputType = .text()
  private var pickerData: [String] = []
  private var numericFilter: NumericTextInputFilter?
  private var initialPlaceholder: String?

  var onChange: ((Any) -> Void)?
  var onTextChange: ((String) -> Void)?
  var onDateChange: ((Date) -> Void)?
  var onPickerChange: ((String, Int) -> Void)?
  var onSwitchChange: ((Bool) -> Void)?

  // Public accessors
  var text: String? {
    get {
      switch inputType {
      case .text:
        return textField.text
      case .picker:
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        return selectedRow < pickerData.count ? pickerData[selectedRow] : nil
      default:
        return nil
      }
    }
    set {
      if case .text = inputType {
        textField.text = newValue
      }
    }
  }

  var date: Date? {
    get {
      if case .date = inputType {
        return datePicker.date
      }
      return nil
    }
    set {
      if case .date = inputType, let newDate = newValue {
        datePicker.date = newDate
      }
    }
  }

  var isOn: Bool {
    get {
      if case .toggle = inputType {
        return switchControl.isOn
      }
      return false
    }
    set {
      if case .toggle = inputType {
        switchControl.isOn = newValue
      }
    }
  }

  var isEditable: Bool = true {
    didSet {
      updateEditableState()
    }
  }

  // MARK: - Public Access
  var textFieldReference: UITextField? {
    if case .text = inputType {
      return textField
    }
    return nil
  }

  // MARK: - Initializers

  convenience init(
    labelText: String,
    inputType: InputType,
    isEditable: Bool = true,
    placeholder: String? = nil
  ) {
    self.init(frame: .zero)
    self.inputType = inputType
    self.isEditable = isEditable
    self.initialPlaceholder = placeholder
    configure(labelText: labelText)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  // MARK: - Configuration

  func configure(labelText: String) {
    titleLabel.text = labelText
    setupInputElement()
    setupTargets()
    if let placeholder = initialPlaceholder, case .text = inputType {
      setPlaceholder(placeholder)
    }
  }

  private func setupInputElement() {
    // Remove all input elements first
    textField.removeFromSuperview()
    datePicker.removeFromSuperview()
    pickerView.removeFromSuperview()
    switchControl.removeFromSuperview()

    switch inputType {
    case .text(let keyboardType):
      containerView.addSubview(textField)
      textField.keyboardType = keyboardType
      setupTextFieldConstraints()

    case .date(let mode):
      containerView.addSubview(datePicker)
      datePicker.datePickerMode = mode
      setupDatePickerConstraints()

    case .picker(let data):
      containerView.addSubview(pickerView)
      pickerData = data
      pickerView.dataSource = self
      pickerView.delegate = self
      setupPickerViewConstraints()

    case .toggle(let isOn):
      containerView.addSubview(switchControl)
      switchControl.isOn = isOn
      setupSwitchConstraints()
    }
  }

  private func setupTargets() {
    switch inputType {
    case .text:
      textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    case .date:
      datePicker.addTarget(self, action: #selector(datePickerDidChange), for: .valueChanged)
    case .toggle:
      switchControl.addTarget(self, action: #selector(switchDidChange), for: .valueChanged)
    case .picker:
      break  // Handled by delegate methods
    }
  }

  private func updateEditableState() {
    switch inputType {
    case .text:
      textField.isUserInteractionEnabled = isEditable
    case .date:
      datePicker.isUserInteractionEnabled = isEditable
    case .picker:
      pickerView.isUserInteractionEnabled = isEditable
    case .toggle:
      switchControl.isUserInteractionEnabled = isEditable
    }
  }

  // MARK: - Setup

  private func setupUI() {
    // Add container view
    addSubview(containerView)

    // Add label to container
    containerView.addSubview(titleLabel)

    setupContainerConstraints()
  }

  private func setupContainerConstraints() {
    // Container view constraints
    containerView.edgesToSuperview()

    // Title label constraints
    titleLabel.topToSuperview(offset: UIConstants.mediumSpacing)
    titleLabel.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
  }

  private func setupTextFieldConstraints() {
    textField.topToBottom(of: titleLabel, offset: UIConstants.smallSpacing)
    textField.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
    textField.bottomToSuperview(offset: -UIConstants.mediumSpacing)
  }

  private func setupDatePickerConstraints() {
    datePicker.topToBottom(of: titleLabel, offset: UIConstants.smallSpacing)
    datePicker.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
    datePicker.bottomToSuperview(offset: -UIConstants.mediumSpacing)
  }

  private func setupPickerViewConstraints() {
    pickerView.topToBottom(of: titleLabel, offset: UIConstants.smallSpacing)
    pickerView.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
    pickerView.bottomToSuperview(offset: -UIConstants.mediumSpacing)
    pickerView.height(120)
  }

  private func setupSwitchConstraints() {
    switchControl.topToBottom(of: titleLabel, offset: UIConstants.smallSpacing)
    switchControl.leadingToSuperview(offset: UIConstants.standardPadding)
    switchControl.bottomToSuperview(offset: -UIConstants.mediumSpacing)
  }

  // MARK: - Actions

  @objc private func textFieldDidChange() {
    var current = textField.text ?? ""
    if let filter = numericFilter {
      let sanitized = filter.sanitize(current)
      if sanitized != current {
        textField.text = sanitized
        current = sanitized
      }
    }
    onTextChange?(current)
    onChange?(current)
  }

  @objc private func datePickerDidChange() {
    let date = datePicker.date
    onDateChange?(date)
    onChange?(date)
  }

  @objc private func switchDidChange() {
    let isOn = switchControl.isOn
    onSwitchChange?(isOn)
    onChange?(isOn)
  }

  // MARK: - Public Methods

  func setPlaceholder(_ placeholder: String) {
    if case .text = inputType {
      textField.placeholder = placeholder
    }
  }

  func setReturnKeyType(_ returnKeyType: UIReturnKeyType) {
    if case .text = inputType {
      textField.returnKeyType = returnKeyType
    }
  }

  func setDelegate(_ delegate: UITextFieldDelegate?) {
    if case .text = inputType {
      textField.delegate = delegate
    }
  }

  // Enable numeric-only input with locale-aware decimal separator and fraction limit
  func enableNumericInput(maxFractionDigits: Int = 2) {
    numericFilter = NumericTextInputFilter(maxFractionDigits: maxFractionDigits)
    if case .text = inputType {
      textField.keyboardType = .decimalPad
    }
  }

  @discardableResult
  override func becomeFirstResponder() -> Bool {
    switch inputType {
    case .text:
      return textField.becomeFirstResponder()
    default:
      return false
    }
  }

  @discardableResult
  override func resignFirstResponder() -> Bool {
    switch inputType {
    case .text:
      return textField.resignFirstResponder()
    default:
      return false
    }
  }

  func selectPickerRow(_ row: Int, animated: Bool = true) {
    if case .picker = inputType, row < pickerData.count {
      pickerView.selectRow(row, inComponent: 0, animated: animated)
    }
  }
}

// MARK: - UIPickerView DataSource & Delegate

extension InputContainerView: UIPickerViewDataSource, UIPickerViewDelegate {

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return pickerData.count
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
    -> String?
  {
    return row < pickerData.count ? pickerData[row] : nil
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard row < pickerData.count else { return }
    let selectedValue = pickerData[row]
    onPickerChange?(selectedValue, row)
    onChange?(selectedValue)
  }
}
