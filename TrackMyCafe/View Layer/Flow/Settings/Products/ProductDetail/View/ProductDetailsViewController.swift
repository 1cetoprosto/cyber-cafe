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

  // MARK: - Recipe UI
  private lazy var recipeTitleLabel: UILabel = {
    let label = UILabel()
    label.text = R.string.global.recipe()
    label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    label.textColor = UIColor.Main.text
    return label
  }()

  private lazy var recipeStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.distribution = .fill
    return stackView
  }()

  private lazy var addIngredientButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.addIngredient(), for: .normal)
    button.addTarget(self, action: #selector(addIngredientAction), for: .touchUpInside)
    return button
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
    let currencySymbol =
      RequestManager.shared.settings?.currencySymbol
      ?? ((Locale.current.languageCode == "uk")
        ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)
    priceInputContainer.enableCurrencySuffix(symbol: currencySymbol)
    priceInputContainer.setReturnKeyType(.done)

    // Add containers to stack
    mainStackView.addArrangedSubview(nameInputContainer)
    mainStackView.addArrangedSubview(priceInputContainer)

    // Add recipe section
    mainStackView.addArrangedSubview(recipeTitleLabel)
    mainStackView.addArrangedSubview(recipeStackView)
    mainStackView.addArrangedSubview(addIngredientButton)

    updateRecipeUI()
  }

  private func updateRecipeUI() {
    recipeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

    for (index, item) in viewModel.currentRecipe.enumerated() {
      let itemView = createRecipeItemView(item: item, index: index)
      recipeStackView.addArrangedSubview(itemView)
    }
  }

  private func createRecipeItemView(item: RecipeItemModel, index: Int) -> UIView {
    let container = UIView()
    container.backgroundColor = UIColor.Main.secondaryBackground
    container.layer.cornerRadius = 8

    let nameLabel = UILabel()
    nameLabel.text = item.ingredientName
    nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    nameLabel.textColor = UIColor.Main.text

    let quantityLabel = UILabel()
    quantityLabel.text = "\(item.quantity) \(item.unit)"
    quantityLabel.font = UIFont.systemFont(ofSize: 14)
    quantityLabel.textColor = UIColor.Main.secondaryText

    let deleteButton = UIButton(type: .system)
    deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
    deleteButton.tintColor = .red
    deleteButton.tag = index
    deleteButton.addTarget(self, action: #selector(deleteRecipeItemAction(_:)), for: .touchUpInside)

    container.addSubview(nameLabel)
    container.addSubview(quantityLabel)
    container.addSubview(deleteButton)

    nameLabel.edgesToSuperview(
      excluding: .right, insets: .init(top: 8, left: 12, bottom: 28, right: 12))
    quantityLabel.topToBottom(of: nameLabel, offset: 4)
    quantityLabel.left(to: nameLabel)

    deleteButton.centerYToSuperview()
    deleteButton.rightToSuperview(offset: -12)
    deleteButton.width(30)
    deleteButton.height(30)

    container.height(60)

    return container
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
    addIngredientButton.height(UIConstants.buttonHeight)

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

    viewModel.onRecipeChanged = { [weak self] in
      self?.updateRecipeUI()
    }

    Task {
      await viewModel.fetchIngredients()
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
  @objc func addIngredientAction() {
    let ingredients = viewModel.allIngredients

    let alert = UIAlertController(
      title: R.string.global.selectIngredient(), message: nil,
      preferredStyle: .actionSheet)

    for ingredient in ingredients {
      alert.addAction(
        UIAlertAction(title: ingredient.name, style: .default) { [weak self] _ in
          self?.showQuantityInput(for: ingredient)
        })
    }

    alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel, handler: nil))

    if let popoverController = alert.popoverPresentationController {
      popoverController.sourceView = addIngredientButton
      popoverController.sourceRect = addIngredientButton.bounds
    }

    present(alert, animated: true, completion: nil)
  }

  private func showQuantityInput(for ingredient: IngredientModel) {
    let message = String(
      format: NSLocalizedString("enterQuantityPerUnit", comment: ""), ingredient.unit.rawValue)
    let alert = UIAlertController(title: ingredient.name, message: message, preferredStyle: .alert)

    alert.addTextField { textField in
      textField.keyboardType = .decimalPad
      textField.placeholder = "0.0"
    }

    alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel, handler: nil))
    alert.addAction(
      UIAlertAction(title: NSLocalizedString("add", comment: ""), style: .default) {
        [weak self] _ in
        guard let text = alert.textFields?.first?.text,
          let quantity = Double(text.replacingOccurrences(of: ",", with: "."))
        else { return }
        self?.viewModel.addRecipeItem(ingredient: ingredient, quantity: quantity)
      })

    present(alert, animated: true, completion: nil)
  }

  @objc func deleteRecipeItemAction(_ sender: UIButton) {
    viewModel.removeRecipeItem(at: sender.tag)
  }

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
