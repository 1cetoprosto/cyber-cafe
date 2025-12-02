//
//  CostDetailsListViewController.swift
//  TrackMyCafe
//
//  Created by Leonid Kvit on 07.11.2022.
//

import RswiftResources
import TinyConstraints
import UIKit

final class CostDetailsListViewController: UIViewController {

  // MARK: - Properties
  private let viewModel: CostDetailsViewModelType
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
      labelText: R.string.global.costName(),
      inputType: .text(keyboardType: .default),
      isEditable: true,
      placeholder: R.string.global.costNamePlaceholder()
    )
    return container
  }()

  // Price input container
  private lazy var priceInputContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: R.string.global.costSum(),
      inputType: .text(keyboardType: .decimalPad),
      isEditable: true,
      placeholder: R.string.global.costSumPlaceholder()
    )
    return container
  }()

  // MARK: - Action Button
  private lazy var saveButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
    return button
  }()

  // MARK: - Init
  init(viewModel: CostDetailsViewModelType) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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
    priceInputContainer.enableNumericInput(maxFractionDigits: 2)
    let currencySymbol = RequestManager.shared.settings?.currencySymbol
      ?? ((Locale.current.languageCode == "uk") ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)
    priceInputContainer.enableCurrencySuffix(symbol: currencySymbol)
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
    // Save button bottom constraint using standard keyboardLayoutGuide (iOS 15+)
    saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(
      equalTo: view.keyboardLayoutGuide.topAnchor,
      constant: -UIConstants.standardPadding
    )
    saveButtonBottomConstraint.isActive = true
  }

  private func setupData() {
    dateInputContainer.date = viewModel.costDate
    nameInputContainer.text = viewModel.costName
    if viewModel.costSum > 0 {
      priceInputContainer.text = viewModel.costSum.decimalFormat
    } else {
      priceInputContainer.text = nil
    }
  }

  private func setupKeyboardHandling() {
    // Standard handling: rely on keyboardLayoutGuide for layout and provide Done accessory.
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
  @objc private func saveAction() {
    let name = nameInputContainer.text
    let sumText = priceInputContainer.text

    guard viewModel.validate(name: name, sumText: sumText) else {
      PopupFactory.showPopup(
        title: R.string.global.error(),
        description: R.string.global.fillAllFields()
      ) {}
      return
    }

    let sum = viewModel.parsedSum(from: sumText) ?? 0.0

    saveButton.isEnabled = false
    Task { [weak self] in
      guard let self = self else { return }
      do {
        try await self.viewModel.saveCostModel(
          costDate: self.dateInputContainer.date ?? Date(),
          costName: name,
          costSum: sum
        )
        await MainActor.run {
          self.navigationController?.popViewController(animated: true)
        }
      } catch {
        await MainActor.run {
          PopupFactory.showPopup(
            title: R.string.global.error(),
            description: error.localizedDescription
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

  deinit {}
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

  func textFieldDidBeginEditing(_ textField: UITextField) {
    // If price field starts with default zero value, clear it for convenient input
    if textField == priceInputContainer.textFieldReference {
      let current = textField.text?.trimmed ?? ""
      if current == "0" || current == "0,0" || current == "0.0" {
        textField.text = ""
      }
    }
  }

}
