//
//  CostDetailsListViewController.swift
//  TrackMyCafe
//
//  Created by Leonid Kvit on 07.11.2022.
//

import UIKit
import RswiftResources

class CostDetailsListViewController: UIViewController {

  // MARK: - Properties
  var viewModel: CostDetailsViewModelType?
  private var saveButtonBottomConstraint: NSLayoutConstraint!

  // MARK: - UI Elements

  // MARK: - Scroll View & Main Container
  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.keyboardDismissMode = .onDrag
    return scrollView
  }()

  private lazy var mainStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = UIConstants.standardPadding
    stackView.distribution = .fill
    stackView.alignment = .fill
    return stackView
  }()

  // MARK: - Date Section
  private lazy var dateInputContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: R.string.global.costDate(),
      inputType: .date(mode: .date),
      isEditable: true
    )
    return container
  }()

  // MARK: - Name Section
  private lazy var nameInputContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: "Name",
      inputType: .text(keyboardType: .default),
      isEditable: true
    )
    container.translatesAutoresizingMaskIntoConstraints = false
    return container
  }()

  // MARK: - Price Section
  private lazy var priceInputContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: "Price",
      inputType: .text(keyboardType: .decimalPad),
      isEditable: true
    )
    container.translatesAutoresizingMaskIntoConstraints = false
    return container
  }()

  // MARK: - Action Button
  private lazy var saveButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
    return button
  }()

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

    // Add subviews
    view.addSubview(scrollView)
    view.addSubview(saveButton)
    scrollView.addSubview(mainStackView)

    // Configure input containers
    nameInputContainer.setDelegate(self)
    nameInputContainer.setReturnKeyType(.next)

    priceInputContainer.setDelegate(self)
    priceInputContainer.setReturnKeyType(.done)

    // Add containers to stack view
    mainStackView.addArrangedSubview(dateInputContainer)
    mainStackView.addArrangedSubview(nameInputContainer)
    mainStackView.addArrangedSubview(priceInputContainer)
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
      dateInputContainer.heightAnchor.constraint(
        equalToConstant: UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding),
      nameInputContainer.heightAnchor.constraint(
        equalToConstant: UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding),
      priceInputContainer.heightAnchor.constraint(
        equalToConstant: UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding),

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
      dateInputContainer.date = viewModel.costDate
      nameInputContainer.text = viewModel.costName
      priceInputContainer.text = viewModel.costSum.formatted(.currency(code: "USD"))
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

      addDoneButtonToTextField(priceInputContainer.textFieldReference ?? UITextField())

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

    guard let name = nameInputContainer.text, !name.isEmpty else {
      showValidationError()
      return
    }

    guard let priceText = priceInputContainer.text, !priceText.isEmpty,
      let price = Double(priceText)
    else {
      showValidationError()
      return
    }

    viewModel.saveCostModel(
      costDate: dateInputContainer.date ?? Date(), costName: name, costSum: price)
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
    // Check which container's text field is active and navigate accordingly
    if textField == nameInputContainer.textFieldReference {
      priceInputContainer.becomeFirstResponder()
    } else {
      textField.resignFirstResponder()
    }
    return true
  }
}
