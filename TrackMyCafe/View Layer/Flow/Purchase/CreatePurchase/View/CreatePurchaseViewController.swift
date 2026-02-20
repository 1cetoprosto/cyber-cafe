//
//  CreatePurchaseViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import TinyConstraints
import UIKit

class CreatePurchaseViewController: UIViewController {

    private let viewModel: CreatePurchaseViewModelType
    private var ingredients: [IngredientModel] = []
    private var selectedIngredientId: String?
    private var saveButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - UI Elements

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

    private lazy var dateInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.costDate(),
            inputType: .date(mode: .date),
            isEditable: true
        )
        return container
    }()

    private lazy var ingredientInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.selectIngredient(),
            inputType: .text(keyboardType: .default),
            isEditable: true,
            placeholder: R.string.global.selectIngredient(),
            isSelection: true
        )
        // Add tap gesture for selection to the text field directly (since inputView blocks interaction)
        // But InputContainerView handles interactions. Let's add tap to the whole container.
        let tap = UITapGestureRecognizer(target: self, action: #selector(ingredientTapped))
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true

        // Also ensure text field delegate blocks editing if needed, but inputView = UIView() handles it.
        // We need to make sure the tap gesture isn't consumed by subviews if they don't handle it.
        return container
    }()

    private lazy var quantityInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.quantity(),
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: "0"
        )
        return container
    }()

    private lazy var priceInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.pricePerUnit(),
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: "0.00"
        )
        return container
    }()

    private lazy var saveButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.savePurchase(), for: .normal)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(viewModel: CreatePurchaseViewModelType) {
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
        setupKeyboardHandling()
        setupDoneButtons()
        setupInitialValues()
        loadIngredients()
    }

    private func setupDoneButtons() {
        // Add toolbar to numeric fields
        addDoneButtonToTextField(quantityInputContainer.textFieldReference)
        addDoneButtonToTextField(priceInputContainer.textFieldReference)
    }

    private func setupInitialValues() {
        dateInputContainer.date = viewModel.initialDate
        quantityInputContainer.text = viewModel.initialQuantity
        priceInputContainer.text = viewModel.initialPrice
        selectedIngredientId = viewModel.initialIngredientId

        if viewModel.isEditing {
            title = R.string.global.editPurchase()
            saveButton.setTitle(R.string.global.updatePurchase(), for: .normal)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        if !viewModel.isEditing {
            title = R.string.global.newPurchase()
        }
        view.backgroundColor = UIColor.Main.background

        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(mainStackView)

        mainStackView.addArrangedSubview(dateInputContainer)
        mainStackView.addArrangedSubview(ingredientInputContainer)
        mainStackView.addArrangedSubview(quantityInputContainer)
        mainStackView.addArrangedSubview(priceInputContainer)

        // Configure inputs
        quantityInputContainer.enableNumericInput(maxFractionDigits: 2)
        priceInputContainer.enableNumericInput(maxFractionDigits: 2)

        let currencySymbol =
            RequestManager.shared.settings?.currencySymbol
            ?? ((Locale.current.languageCode == "uk")
                ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)
        priceInputContainer.enableCurrencySuffix(symbol: currencySymbol)
    }

    private func setupConstraints() {
        scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)

        mainStackView.edgesToSuperview(
            insets: .init(
                top: UIConstants.largeSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.largeSpacing,
                right: UIConstants.standardPadding
            ))
        mainStackView.width(to: scrollView, offset: -2 * UIConstants.standardPadding)

        let containerHeight =
            UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding
        dateInputContainer.height(containerHeight)
        ingredientInputContainer.height(containerHeight)
        quantityInputContainer.height(containerHeight)
        priceInputContainer.height(containerHeight)

        saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        saveButton.height(UIConstants.buttonHeight)

        saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(
            equalTo: view.keyboardLayoutGuide.topAnchor,
            constant: -UIConstants.standardPadding
        )
        saveButtonBottomConstraint.isActive = true
    }

    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func addDoneButtonToTextField(_ textField: UITextField?) {
        guard let textField = textField else { return }
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
            title: R.string.global.actionOk(),
            style: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
    }

    private func loadIngredients() {
        viewModel.fetchIngredients { [weak self] ingredients in
            self?.ingredients = ingredients

            // Pre-select ingredient if editing
            if let selectedId = self?.selectedIngredientId,
                let ingredient = ingredients.first(where: { $0.id == selectedId })
            {
                self?.ingredientInputContainer.text = ingredient.name
            }
        }
    }

    // MARK: - Actions

    @objc private func ingredientTapped() {
        let selectionVC = SelectItemViewController(
            title: R.string.global.selectIngredient(),
            items: ingredients.map { $0.name },
            onSelect: { [weak self] (selectedName: String) in
                guard let self = self else { return }
                self.ingredientInputContainer.text = selectedName
                if let ingredient = self.ingredients.first(where: { $0.name == selectedName }) {
                    self.selectedIngredientId = ingredient.id
                }
            }
        )
        navigationController?.pushViewController(selectionVC, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func saveTapped() {
        guard let ingredientId = selectedIngredientId else {
            showAlert(message: R.string.global.pleaseSelectIngredient())
            return
        }

        guard let qtyString = quantityInputContainer.text, let qty = Double(qtyString) else {
            showAlert(message: R.string.global.invalidQuantity())
            return
        }

        guard let priceString = priceInputContainer.text, let price = Double(priceString) else {
            showAlert(message: R.string.global.invalidPrice())
            return
        }

        viewModel.savePurchase(
            date: dateInputContainer.date ?? Date(),
            ingredientId: ingredientId,
            quantity: qty,
            price: price
        ) { [weak self] success, errorMsg in
            DispatchQueue.main.async {
                if success {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    self?.showAlert(message: errorMsg ?? R.string.global.wentWrong())
                }
            }
        }
    }

    private func showAlert(message: String) {
        PopupFactory.showPopup(title: R.string.global.error(), description: message)
    }
}

// MARK: - TextField Delegate
extension CreatePurchaseViewController: UITextFieldDelegate {
    // Add delegate methods if needed
}
