//
//  ProductDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.11.2021.
//

import TinyConstraints
import UIKit

class ProductDetailsViewController: UIViewController {

  // MARK: - UI: Scroll & Stack
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

  // MARK: - Inputs
  private lazy var nameInputContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: R.string.global.productName(),
      inputType: .text(keyboardType: .default),
      isEditable: true,
      placeholder: R.string.global.enterProductName()
    )
    return container
  }()

  private lazy var priceInputContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: R.string.global.price(),
      inputType: .text(keyboardType: .decimalPad),
      isEditable: true,
      placeholder: R.string.global.enterPrice()
    )
    return container
  }()

  // MARK: - Bottom Buttons
  private lazy var saveButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
    return button
  }()

  private let viewModel: ProductDetailsViewModelType

  init(viewModel: ProductDetailsViewModelType) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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

  // MARK: - Setup
  private func setupUI() {
    view.backgroundColor = UIColor.Main.background
    title = R.string.global.product()

    // Add subviews
    view.addSubview(scrollView)
    view.addSubview(saveButton)
    scrollView.addSubview(mainStackView)

    // Configure input containers
    nameInputContainer.setDelegate(self)
    nameInputContainer.setReturnKeyType(.next)

    priceInputContainer.setDelegate(self)
    priceInputContainer.enableNumericInput(maxFractionDigits: 2)
    let currencySymbol = RequestManager.shared.settings?.currencySymbol
      ?? ((Locale.current.languageCode == "uk") ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)
    priceInputContainer.enableCurrencySuffix(symbol: currencySymbol)
    priceInputContainer.setReturnKeyType(.done)

    // Add containers to stack
    mainStackView.addArrangedSubview(nameInputContainer)
    mainStackView.addArrangedSubview(priceInputContainer)
  }

  private func setupNavigationBar() {
    title = R.string.global.product()
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
    nameInputContainer.height(containerHeight)
    priceInputContainer.height(containerHeight)

    // Save button constraints
    saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
    saveButton.height(UIConstants.buttonHeight)
    let saveButtonBottom = saveButton.bottomAnchor.constraint(
      equalTo: view.keyboardLayoutGuide.topAnchor,
      constant: -UIConstants.standardPadding
    )
    saveButtonBottom.isActive = true
  }

  private func setupData() {
    nameInputContainer.text = viewModel.productName
    if viewModel.productPrice > 0 {
      priceInputContainer.text = viewModel.productPrice.decimalFormat
    } else {
      priceInputContainer.text = nil
    }
  }

  private func setupKeyboardHandling() {
    // Add Done accessory to numeric price field
    addDoneButtonToTextField(priceInputContainer.textFieldReference ?? UITextField())

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
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
  @objc func saveAction(param: UIButton) {
    let nameText = nameInputContainer.text
    let priceText = priceInputContainer.text

    let trimmedName = (nameText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let priceRawText = priceText ?? ""
    guard viewModel.validate(name: nameText, priceText: priceText) else {
      let message: String
      if trimmedName.isEmpty {
        message = R.string.global.pleaseEnterProductName()
      } else if priceRawText.isEmpty {
        message = R.string.global.enterPrice()
      } else {
        message = R.string.global.fillAllFields()
      }
      PopupFactory.showPopup(title: R.string.global.error(), description: message) {}
      return
    }

    let parsedPrice = viewModel.parsedPrice(from: priceText) ?? 0.0

    saveButton.isEnabled = false
    Task { [weak self] in
      guard let self = self else { return }
      do {
        try await self.viewModel.saveProductPrice(name: nameText, price: parsedPrice)
        await MainActor.run {
          self.navigationController?.popViewController(animated: true)
        }
      } catch {
        await MainActor.run {
          PopupFactory.showPopup(
            title: R.string.global.error(), description: R.string.global.failedToSaveProductPrice()
          ) {}
        }
      }
      await MainActor.run {
        self.saveButton.isEnabled = true
      }
    }
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }

}

// MARK: - UITextFieldDelegate
extension ProductDetailsViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == nameInputContainer.textFieldReference {
      priceInputContainer.becomeFirstResponder()
    } else {
      textField.resignFirstResponder()
    }
    return true
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == priceInputContainer.textFieldReference {
      let current = textField.text?.trimmed ?? ""
      if current == "0" || current == "0,0" || current == "0.0" {
        textField.text = ""
      }
    }
  }
}
