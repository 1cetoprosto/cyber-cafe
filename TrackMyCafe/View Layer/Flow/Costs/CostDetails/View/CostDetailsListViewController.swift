//
//  CostDetailsListViewController.swift
//  TrackMyCafe
//
//  Created by Leonid Kvit on 07.11.2022.
//

import RswiftResources
import TinyConstraints
import UIKit

class CostDetailsListViewController: UIViewController {

  // MARK: - Properties
  var viewModel: CostDetailsViewModelType?
  private var saveButtonBottomConstraint: NSLayoutConstraint!

  // MARK: - UI Elements

  // MARK: - Scroll View & Main Container
  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.showsVerticalScrollIndicator = false
    scrollView.keyboardDismissMode = .onDrag
    return scrollView
  }()

  private lazy var mainStackView: UIStackView = {
    let stackView = UIStackView()
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
        labelText: R.string.global.costNamePlaceholder(),
      inputType: .text(keyboardType: .default),
      isEditable: true
    )
    return container
  }()

  // Price input container
  private lazy var priceInputContainer: InputContainerView = {
    let container = InputContainerView(
        labelText: R.string.global.costSum(),
      inputType: .text(keyboardType: .decimalPad),
      isEditable: true
    )
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
    // ScrollView constraints
    scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
    scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)

    // Main StackView constraints
    mainStackView.edgesToSuperview(
      insets: .init(
        top: UIConstants.largeSpacing,
        left: UIConstants.standardPadding,
        bottom: UIConstants.largeSpacing,
        right: UIConstants.standardPadding
      ))
    mainStackView.width(to: scrollView, offset: -2 * UIConstants.standardPadding)

    // Container heights
    let containerHeight =
      UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding
    dateInputContainer.height(containerHeight)
    nameInputContainer.height(containerHeight)
    priceInputContainer.height(containerHeight)

    // Save Button constraints
    saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
    saveButton.height(UIConstants.buttonHeight)

    // Save button bottom constraint for keyboard handling
    saveButtonBottomConstraint = saveButton.bottomToSuperview(
      offset: -UIConstants.standardPadding, usingSafeArea: true)
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
