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
    private var selectedPaymentAccount: PaymentAccount?
    private var isTotalAmountManuallyEdited = false
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
        stackView.spacing = UIConstants.standardSpacing
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var dateAndPaymentRowStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [dateInputContainer, paymentMethodContainer])
        stackView.axis = .horizontal
        stackView.spacing = UIConstants.standardSpacing
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

    private lazy var quantityAndPriceRowStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [quantityInputContainer, priceInputContainer])
        stackView.axis = .horizontal
        stackView.spacing = UIConstants.standardSpacing
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
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

    private lazy var totalAmountInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.costSum(),
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: "0.00"
        )
        return container
    }()

    private lazy var paymentMethodSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [R.string.global.cash(), R.string.global.card()])
        control.selectedSegmentIndex = UISegmentedControl.noSegment
        control.addTarget(self, action: #selector(paymentMethodChanged), for: .valueChanged)
        return control
    }()

    private lazy var paymentMethodContainer: UIView = {
        let container = UIView()

        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.TableView.cellBackground
        backgroundView.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = R.string.global.paymentMethod()
        titleLabel.applyDynamic(Typography.footnote)
        titleLabel.textColor = UIColor.Main.text
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85

        container.addSubview(backgroundView)
        backgroundView.addSubview(titleLabel)
        backgroundView.addSubview(paymentMethodSegmentedControl)

        backgroundView.edgesToSuperview()

        titleLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        titleLabel.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))

        paymentMethodSegmentedControl.topToBottom(of: titleLabel, offset: UIConstants.smallSpacing)
        paymentMethodSegmentedControl.horizontalToSuperview(
            insets: .horizontal(UIConstants.standardPadding))
        paymentMethodSegmentedControl.bottomToSuperview(offset: -UIConstants.mediumSpacing)

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
        addDoneButtonToTextField(totalAmountInputContainer.textFieldReference)
    }

    private func setupInitialValues() {
        dateInputContainer.date = viewModel.initialDate
        quantityInputContainer.text = viewModel.initialQuantity
        priceInputContainer.text = viewModel.initialPrice

        if viewModel.isEditing {
            updateTotalAmountDisplay(amount: viewModel.initialTotalAmount)
            isTotalAmountManuallyEdited = isInitialTotalAmountCustom()
        } else {
            totalAmountInputContainer.text = nil
            isTotalAmountManuallyEdited = false
        }

        selectedIngredientId = viewModel.initialIngredientId
        selectedPaymentAccount = viewModel.initialPaymentAccount

        if let paymentAccount = selectedPaymentAccount {
            paymentMethodSegmentedControl.selectedSegmentIndex = paymentAccount == .cash ? 0 : 1
        }

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

        mainStackView.addArrangedSubview(dateAndPaymentRowStack)
        mainStackView.addArrangedSubview(ingredientInputContainer)
        mainStackView.addArrangedSubview(quantityAndPriceRowStack)
        mainStackView.addArrangedSubview(totalAmountInputContainer)

        // Configure inputs
        quantityInputContainer.enableNumericInput(maxFractionDigits: 2)
        priceInputContainer.enableNumericInput(maxFractionDigits: 2)
        totalAmountInputContainer.enableNumericInput(maxFractionDigits: 2)

        let currencySymbol =
            RequestManager.shared.settings?.currencySymbol
            ?? ((Locale.current.languageCode == "uk")
                ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)
        priceInputContainer.enableCurrencySuffix(symbol: currencySymbol)
        totalAmountInputContainer.enableCurrencySuffix(symbol: currencySymbol)

        quantityInputContainer.onTextChange = { [weak self] _ in
            self?.isTotalAmountManuallyEdited = false
            self?.recalculateTotalAmount()
        }
        priceInputContainer.onTextChange = { [weak self] _ in
            self?.isTotalAmountManuallyEdited = false
            self?.recalculateTotalAmount()
        }
        totalAmountInputContainer.onTextChange = { [weak self] _ in
            self?.isTotalAmountManuallyEdited = true
        }
    }

    private func setupConstraints() {
        scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)

        let horizontalInset = UIConstants.standardPadding
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        let fillWidth = mainStackView.widthAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.widthAnchor,
            constant: -2 * horizontalInset
        )
        fillWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: UIConstants.largeSpacing
            ),
            mainStackView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -UIConstants.largeSpacing
            ),
            mainStackView.centerXAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            mainStackView.leadingAnchor.constraint(
                greaterThanOrEqualTo: scrollView.frameLayoutGuide.leadingAnchor,
                constant: horizontalInset
            ),
            mainStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: scrollView.frameLayoutGuide.trailingAnchor,
                constant: -horizontalInset
            ),
            fillWidth,
            mainStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
        ])

        dateInputContainer.setContentHuggingPriority(.required, for: .horizontal)
        dateInputContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        paymentMethodContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        paymentMethodContainer.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)

        dateInputContainer.widthAnchor
            .constraint(equalTo: dateAndPaymentRowStack.widthAnchor, multiplier: 0.42)
            .isActive = true

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

    @objc private func paymentMethodChanged() {
        switch paymentMethodSegmentedControl.selectedSegmentIndex {
        case 0:
            selectedPaymentAccount = .cash
        case 1:
            selectedPaymentAccount = .card
        default:
            selectedPaymentAccount = nil
        }
    }

    private func recalculateTotalAmount() {
        guard !isTotalAmountManuallyEdited else { return }
        let quantity = Double(quantityInputContainer.text ?? "") ?? 0
        let price = Double(priceInputContainer.text ?? "") ?? 0

        guard !(quantity.isZero && price.isZero) else {
            totalAmountInputContainer.text = nil
            return
        }

        updateTotalAmountDisplay(amount: quantity * price)
    }

    private func updateTotalAmountDisplay(amount: Double) {
        totalAmountInputContainer.text = String(format: "%.2f", amount)
    }

    private func isInitialTotalAmountCustom() -> Bool {
        guard viewModel.isEditing else { return false }

        let quantity = Double(viewModel.initialQuantity) ?? 0
        let price = Double(viewModel.initialPrice) ?? 0
        let calculated = quantity * price
        return abs(viewModel.initialTotalAmount - calculated) > 0.000_1
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

        guard
            let totalString = totalAmountInputContainer.text,
            let totalAmount = Double(totalString)
        else {
            showAlert(message: R.string.global.fillAllFields())
            return
        }

        guard let paymentAccount = selectedPaymentAccount else {
            showAlert(message: R.string.global.fillAllFields())
            return
        }

        viewModel.savePurchase(
            date: dateInputContainer.date ?? Date(),
            ingredientId: ingredientId,
            quantity: qty,
            price: price,
            totalAmount: totalAmount,
            paymentAccount: paymentAccount
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
