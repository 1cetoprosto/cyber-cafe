//
//  CostDetailsListViewController.swift
//  TrackMyCafe
//
//  Created by Leonid Kvit on 07.11.2022.
//

import UIKit

class CostDetailsListViewController: UIViewController {

  // MARK: - Properties
  var viewModel: CostDetailsViewModelType?

  // MARK: - UI Elements
  private let scrollView = UIScrollView()
  private let mainStackView = UIStackView()

  // Date section
  private let dateContainerView = UIView()
  private let dateLabel = UILabel()
  private let datePicker = UIDatePicker()

  // Name section
  private let nameContainerView = UIView()
  private let nameLabel = UILabel()
  private let nameTextField = UITextField()

  // Price section
  private let priceContainerView = UIView()
  private let priceLabel = UILabel()
  private let priceTextField = UITextField()

  // Save button
  private let saveButton = UIButton(type: .system)
  private var saveButtonBottomConstraint: NSLayoutConstraint!

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupConstraints()
    setupData()
    setupKeyboardHandling()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupNavigationBar()
  }

  // MARK: - Setup Methods
  private func setupUI() {
    view.backgroundColor = UIColor.Main.background

    // Configure scroll view
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.keyboardDismissMode = .onDrag

    // Configure main stack view
    mainStackView.translatesAutoresizingMaskIntoConstraints = false
    mainStackView.axis = .vertical
    mainStackView.spacing = UIConstants.standardPadding
    mainStackView.distribution = .fill
    mainStackView.alignment = .fill

    // Configure date container
    setupDateContainer()

    // Configure name container
    setupNameContainer()

    // Configure price container
    setupPriceContainer()

    // Configure save button
    saveButton.translatesAutoresizingMaskIntoConstraints = false
    saveButton.setTitle(R.string.global.save(), for: .normal)
    saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
    saveButton.setTitleColor(UIColor.Button.title, for: .normal)
    saveButton.backgroundColor = UIColor.Button.background
    saveButton.layer.cornerRadius = UIConstants.buttonCornerRadius
    saveButton.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)

    // Add subviews
    view.addSubview(scrollView)
    view.addSubview(saveButton)
    scrollView.addSubview(mainStackView)

    // Add containers to stack view
    mainStackView.addArrangedSubview(dateContainerView)
    mainStackView.addArrangedSubview(nameContainerView)
    mainStackView.addArrangedSubview(priceContainerView)
  }

  private func setupDateContainer() {
    dateContainerView.translatesAutoresizingMaskIntoConstraints = false
    dateContainerView.backgroundColor = UIColor.TableView.cellBackground
    dateContainerView.layer.cornerRadius = 12

    dateLabel.translatesAutoresizingMaskIntoConstraints = false
    dateLabel.text = R.string.global.costDate()
    dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    dateLabel.textColor = UIColor.Main.text

    datePicker.translatesAutoresizingMaskIntoConstraints = false
    datePicker.datePickerMode = .date
    datePicker.preferredDatePickerStyle = .compact
    datePicker.tintColor = UIColor.Main.accent

    dateContainerView.addSubview(dateLabel)
    dateContainerView.addSubview(datePicker)
  }

  private func setupNameContainer() {
    nameContainerView.translatesAutoresizingMaskIntoConstraints = false
    nameContainerView.backgroundColor = UIColor.TableView.cellBackground
    nameContainerView.layer.cornerRadius = 12

    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.text = R.string.global.costNamePlaceholder()
    nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    nameLabel.textColor = UIColor.Main.text

    nameTextField.translatesAutoresizingMaskIntoConstraints = false
    nameTextField.font = UIFont.systemFont(ofSize: 20)
    nameTextField.textColor = UIColor.Main.text
    nameTextField.backgroundColor = .clear
    nameTextField.borderStyle = .none
    nameTextField.returnKeyType = .next
    nameTextField.delegate = self

    nameContainerView.addSubview(nameLabel)
    nameContainerView.addSubview(nameTextField)
  }

  private func setupPriceContainer() {
    priceContainerView.translatesAutoresizingMaskIntoConstraints = false
    priceContainerView.backgroundColor = UIColor.TableView.cellBackground
    priceContainerView.layer.cornerRadius = 12

    priceLabel.translatesAutoresizingMaskIntoConstraints = false
    priceLabel.text = R.string.global.costSum()
    priceLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    priceLabel.textColor = UIColor.Main.text

    priceTextField.translatesAutoresizingMaskIntoConstraints = false
    priceTextField.placeholder = "0.00"
    priceTextField.font = UIFont.systemFont(ofSize: 20)
    priceTextField.textColor = UIColor.Main.text
    priceTextField.backgroundColor = .clear
    priceTextField.borderStyle = .none
    priceTextField.keyboardType = .decimalPad
    priceTextField.returnKeyType = .done
    priceTextField.delegate = self

    priceContainerView.addSubview(priceLabel)
    priceContainerView.addSubview(priceTextField)
  }

  private func setupNavigationBar() {
    title = R.string.global.cost()
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationItem.largeTitleDisplayMode = .always

    navigationController?.navigationBar.largeTitleTextAttributes = [
      .foregroundColor: UIColor.NavBar.text
    ]
    navigationController?.navigationBar.titleTextAttributes = [
      .foregroundColor: UIColor.NavBar.text
    ]
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      // ScrollView constraints
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(
        equalTo: saveButton.topAnchor, constant: -UIConstants.standardPadding),

      // Main StackView constraints
      mainStackView.topAnchor.constraint(
        equalTo: scrollView.topAnchor, constant: UIConstants.largeSpacing),
      mainStackView.leadingAnchor.constraint(
        equalTo: scrollView.leadingAnchor, constant: UIConstants.standardPadding),
      mainStackView.trailingAnchor.constraint(
        equalTo: scrollView.trailingAnchor, constant: -UIConstants.standardPadding),
      mainStackView.bottomAnchor.constraint(
        equalTo: scrollView.bottomAnchor, constant: -UIConstants.largeSpacing),
      mainStackView.widthAnchor.constraint(
        equalTo: scrollView.widthAnchor, constant: -2 * UIConstants.standardPadding),

      // Container heights
      dateContainerView.heightAnchor.constraint(equalToConstant: UIConstants.imageSize),
      nameContainerView.heightAnchor.constraint(
        equalToConstant: UIConstants.cellHeight + UIConstants.largeSpacing),
      priceContainerView.heightAnchor.constraint(
        equalToConstant: UIConstants.cellHeight + UIConstants.largeSpacing),

      // Date container internal constraints
      dateLabel.topAnchor.constraint(
        equalTo: dateContainerView.topAnchor, constant: UIConstants.mediumSpacing),
      dateLabel.leadingAnchor.constraint(
        equalTo: dateContainerView.leadingAnchor, constant: UIConstants.standardPadding),
      dateLabel.trailingAnchor.constraint(
        equalTo: dateContainerView.trailingAnchor, constant: -UIConstants.standardPadding),

      datePicker.topAnchor.constraint(
        equalTo: dateLabel.bottomAnchor, constant: UIConstants.smallSpacing),
      datePicker.leadingAnchor.constraint(
        equalTo: dateContainerView.leadingAnchor, constant: UIConstants.standardPadding),
      datePicker.trailingAnchor.constraint(
        equalTo: dateContainerView.trailingAnchor, constant: -UIConstants.standardPadding),

      // Name container internal constraints
      nameLabel.topAnchor.constraint(
        equalTo: nameContainerView.topAnchor, constant: UIConstants.mediumSpacing),
      nameLabel.leadingAnchor.constraint(
        equalTo: nameContainerView.leadingAnchor, constant: UIConstants.standardPadding),
      nameLabel.trailingAnchor.constraint(
        equalTo: nameContainerView.trailingAnchor, constant: -UIConstants.standardPadding),

      nameTextField.topAnchor.constraint(
        equalTo: nameLabel.bottomAnchor, constant: UIConstants.smallSpacing),
      nameTextField.leadingAnchor.constraint(
        equalTo: nameContainerView.leadingAnchor, constant: UIConstants.standardPadding),
      nameTextField.trailingAnchor.constraint(
        equalTo: nameContainerView.trailingAnchor, constant: -UIConstants.standardPadding),

      // Price container internal constraints
      priceLabel.topAnchor.constraint(
        equalTo: priceContainerView.topAnchor, constant: UIConstants.mediumSpacing),
      priceLabel.leadingAnchor.constraint(
        equalTo: priceContainerView.leadingAnchor, constant: UIConstants.standardPadding),
      priceLabel.trailingAnchor.constraint(
        equalTo: priceContainerView.trailingAnchor, constant: -UIConstants.standardPadding),

      priceTextField.topAnchor.constraint(
        equalTo: priceLabel.bottomAnchor, constant: UIConstants.smallSpacing),
      priceTextField.leadingAnchor.constraint(
        equalTo: priceContainerView.leadingAnchor, constant: UIConstants.standardPadding),
      priceTextField.trailingAnchor.constraint(
        equalTo: priceContainerView.trailingAnchor, constant: -UIConstants.standardPadding),

      // Save Button constraints
      saveButton.leadingAnchor.constraint(
        equalTo: view.leadingAnchor, constant: UIConstants.standardPadding),
      saveButton.trailingAnchor.constraint(
        equalTo: view.trailingAnchor, constant: -UIConstants.standardPadding),
      saveButton.heightAnchor.constraint(equalToConstant: UIConstants.buttonHeight),
    ])

    // Save button bottom constraint for keyboard handling
    saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(
      equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UIConstants.standardPadding)
    saveButtonBottomConstraint.isActive = true
  }

  private func setupData() {
    if let viewModel = viewModel {
        datePicker.date = viewModel.costDate
        nameTextField.text = viewModel.costName
        priceTextField.text = String(viewModel.costSum)
    }
  }

  private func setupKeyboardHandling() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )

    addDoneButtonToTextField(priceTextField)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    view.addGestureRecognizer(tapGesture)
  }

  private func addDoneButtonToTextField(_ textField: UITextField) {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()

    let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(
        title: R.string.global.actionOk(),
      style: .done,
      target: self,
      action: #selector(dismissKeyboard)
    )

    toolbar.items = [flexSpace, doneButton]
    textField.inputAccessoryView = toolbar
  }

  // MARK: - Actions
  @objc private func saveAction(param: UIButton) {
    guard let viewModel = viewModel else { return }

    guard let name = nameTextField.text, !name.isEmpty else {
      showValidationError()
      return
    }

    guard let priceText = priceTextField.text, !priceText.isEmpty,
      let price = Double(priceText)
    else {
      showValidationError()
      return
    }

    viewModel.saveCostModel(costDate: datePicker.date, costName: name, costSum: price)
    navigationController?.popViewController(animated: true)
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }

  @objc private func keyboardWillShow(notification: NSNotification) {
    guard
      let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        as? CGRect,
      let animationDuration = notification.userInfo?[
        UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
    else {
      return
    }

    let keyboardHeight = keyboardFrame.height
    saveButtonBottomConstraint.constant = -keyboardHeight - UIConstants.smallSpacing

    UIView.animate(withDuration: animationDuration) {
      self.view.layoutIfNeeded()
    }
  }

  @objc private func keyboardWillHide(notification: NSNotification) {
    guard
      let animationDuration = notification.userInfo?[
        UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
    else {
      return
    }

    saveButtonBottomConstraint.constant = -UIConstants.standardPadding

    UIView.animate(withDuration: animationDuration) {
      self.view.layoutIfNeeded()
    }
  }

  private func showValidationError() {
    let alert = UIAlertController(
      title: R.string.global.error(),
      message: R.string.global.fillAllFields(),
      preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: R.string.global.actionOk(), style: .default))
    present(alert, animated: true)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

// MARK: - UITextFieldDelegate
extension CostDetailsListViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == nameTextField {
      priceTextField.becomeFirstResponder()
    } else {
      textField.resignFirstResponder()
    }
    return true
  }
}
