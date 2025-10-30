//
//  InputContainerView.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 30.12.2024.
//

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
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.TableView.cellBackground
    view.layer.cornerRadius = 12
    return view
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    label.textColor = UIColor.Main.text
    return label
  }()

  // Input Elements
  private lazy var textField: UITextField = {
    let textField = UITextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.font = UIFont.systemFont(ofSize: 20)
    textField.textColor = UIColor.Main.text
    textField.backgroundColor = .clear
    textField.borderStyle = .none
    textField.returnKeyType = .next
    return textField
  }()

  private lazy var datePicker: UIDatePicker = {
    let picker = UIDatePicker()
    picker.translatesAutoresizingMaskIntoConstraints = false
    picker.preferredDatePickerStyle = .compact
    picker.datePickerMode = .date
    return picker
  }()

  private lazy var pickerView: UIPickerView = {
    let picker = UIPickerView()
    picker.translatesAutoresizingMaskIntoConstraints = false
    return picker
  }()

  private lazy var switchControl: UISwitch = {
    let switchControl = UISwitch()
    switchControl.translatesAutoresizingMaskIntoConstraints = false
    switchControl.onTintColor = UIColor.Main.accent
    return switchControl
  }()

  // MARK: - Properties

  private var inputType: InputType = .text()
  private var pickerData: [String] = []

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
    isEditable: Bool = true
  ) {
    self.init(frame: .zero)
    self.inputType = inputType
    self.isEditable = isEditable
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
    translatesAutoresizingMaskIntoConstraints = false

    // Add container view
    addSubview(containerView)

    // Add label to container
    containerView.addSubview(titleLabel)

    setupContainerConstraints()
  }

  private func setupContainerConstraints() {
    NSLayoutConstraint.activate([
      // Container view constraints
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      // Title label constraints
      titleLabel.topAnchor.constraint(
        equalTo: containerView.topAnchor,
        constant: UIConstants.mediumSpacing
      ),
      titleLabel.leadingAnchor.constraint(
        equalTo: containerView.leadingAnchor,
        constant: UIConstants.standardPadding
      ),
      titleLabel.trailingAnchor.constraint(
        equalTo: containerView.trailingAnchor,
        constant: -UIConstants.standardPadding
      ),
    ])
  }

  private func setupTextFieldConstraints() {
    NSLayoutConstraint.activate([
      textField.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: UIConstants.smallSpacing
      ),
      textField.leadingAnchor.constraint(
        equalTo: containerView.leadingAnchor,
        constant: UIConstants.standardPadding
      ),
      textField.trailingAnchor.constraint(
        equalTo: containerView.trailingAnchor,
        constant: -UIConstants.standardPadding
      ),
      textField.bottomAnchor.constraint(
        equalTo: containerView.bottomAnchor,
        constant: -UIConstants.mediumSpacing
      ),
    ])
  }

  private func setupDatePickerConstraints() {
    NSLayoutConstraint.activate([
      datePicker.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: UIConstants.smallSpacing
      ),
      datePicker.leadingAnchor.constraint(
        equalTo: containerView.leadingAnchor,
        constant: UIConstants.standardPadding
      ),
      datePicker.trailingAnchor.constraint(
        equalTo: containerView.trailingAnchor,
        constant: -UIConstants.standardPadding
      ),
      datePicker.bottomAnchor.constraint(
        equalTo: containerView.bottomAnchor,
        constant: -UIConstants.mediumSpacing
      ),
    ])
  }

  private func setupPickerViewConstraints() {
    NSLayoutConstraint.activate([
      pickerView.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: UIConstants.smallSpacing
      ),
      pickerView.leadingAnchor.constraint(
        equalTo: containerView.leadingAnchor,
        constant: UIConstants.standardPadding
      ),
      pickerView.trailingAnchor.constraint(
        equalTo: containerView.trailingAnchor,
        constant: -UIConstants.standardPadding
      ),
      pickerView.bottomAnchor.constraint(
        equalTo: containerView.bottomAnchor,
        constant: -UIConstants.mediumSpacing
      ),
      pickerView.heightAnchor.constraint(equalToConstant: 120),
    ])
  }

  private func setupSwitchConstraints() {
    NSLayoutConstraint.activate([
      switchControl.topAnchor.constraint(
        equalTo: titleLabel.bottomAnchor,
        constant: UIConstants.smallSpacing
      ),
      switchControl.leadingAnchor.constraint(
        equalTo: containerView.leadingAnchor,
        constant: UIConstants.standardPadding
      ),
      switchControl.bottomAnchor.constraint(
        equalTo: containerView.bottomAnchor,
        constant: -UIConstants.mediumSpacing
      ),
    ])
  }

  // MARK: - Actions

  @objc private func textFieldDidChange() {
    let text = textField.text ?? ""
    onTextChange?(text)
    onChange?(text)
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
