//
//  CreateIngredientViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 05.02.2026.
//

import TinyConstraints
import UIKit

final class CreateIngredientViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: IngredientListViewModelType
    private let ingredientToEdit: IngredientModel?
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
    
    // Name
    private lazy var nameInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.productName(),
            inputType: .text(keyboardType: .default),
            placeholder: R.string.global.ingredientNamePlaceholder()
        )
        return container
    }()
    
    private lazy var nameExplanationLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.footnote
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 0
        label.text = R.string.global.ingredientNameExplanation()
        return label
    }()
    
    // Cost
    private lazy var costInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.price(),
            inputType: .text(keyboardType: .decimalPad),
            placeholder: R.string.global.costPlaceholder()
        )
        container.enableNumericInput(maxFractionDigits: 2)
        return container
    }()
    
    private lazy var costExplanationLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.footnote
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 0
        label.text = R.string.global.costExplanation()
        return label
    }()
    
    // Stock
    private lazy var stockInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.quantity(),
            inputType: .text(keyboardType: .decimalPad),
            placeholder: R.string.global.stockPlaceholder()
        )
        container.enableNumericInput(maxFractionDigits: 3)
        return container
    }()
    
    private lazy var stockExplanationLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.footnote
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 0
        label.text = R.string.global.stockExplanation()
        return label
    }()
    
    // Unit
    private lazy var unitInputContainer: InputContainerView = {
        let units = MeasurementUnit.allCases.map { $0.localizedName }
        let container = InputContainerView(
            labelText: R.string.global.unitLabel(),
            inputType: .picker(data: units)
        )
        return container
    }()
    
    private lazy var unitExplanationLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.footnote
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 0
        label.text = R.string.global.unitExplanation()
        return label
    }()
    
    // Save Button
    private lazy var saveButton: UIButton = {
        let button = DefaultButton()
        let title = ingredientToEdit == nil ? R.string.global.add() : R.string.global.save()
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    init(viewModel: IngredientListViewModelType, ingredient: IngredientModel? = nil) {
        self.viewModel = viewModel
        self.ingredientToEdit = ingredient
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
        fillData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = ingredientToEdit == nil ? R.string.global.newIngredient() : R.string.global.edit()
        
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(mainStackView)
        
        // Add sections to stack
        addSection(input: nameInputContainer, explanation: nameExplanationLabel)
        addSection(input: costInputContainer, explanation: costExplanationLabel)
        addSection(input: stockInputContainer, explanation: stockExplanationLabel)
        addSection(input: unitInputContainer, explanation: unitExplanationLabel)
    }
    
    private func fillData() {
        guard let ingredient = ingredientToEdit else { return }
        nameInputContainer.text = ingredient.name
        costInputContainer.text = String(format: "%.2f", ingredient.averageCost)
        stockInputContainer.text = String(format: "%.3f", ingredient.stockQuantity)
        unitInputContainer.text = ingredient.unit.localizedName
    }
    
    private func addSection(input: UIView, explanation: UIView) {
        let container = UIStackView(arrangedSubviews: [input, explanation])
        container.axis = .vertical
        container.spacing = 4
        mainStackView.addArrangedSubview(container)
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
                constant: UIConstants.standardPadding
            ),
            mainStackView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -UIConstants.standardPadding
            ),
            mainStackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
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
        addDoneButtonToTextField(costInputContainer.textFieldReference)
        addDoneButtonToTextField(stockInputContainer.textFieldReference)
    }
    
    private func addDoneButtonToTextField(_ textField: UITextField?) {
        guard let textField else { return }
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
        guard let name = nameInputContainer.text, !name.isEmpty,
              let costText = costInputContainer.text,
              let cost = Double(costText.replacingOccurrences(of: ",", with: ".")),
              let stockText = stockInputContainer.text,
              let stock = Double(stockText.replacingOccurrences(of: ",", with: "."))
        else {
            let alert = UIAlertController(
                title: R.string.global.error(),
                message: R.string.global.fillAllFields(),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let selectedUnitString = unitInputContainer.text
        // Find the unit enum that matches the localized string, or default to .pcs
        let unit = MeasurementUnit.allCases.first { $0.localizedName == selectedUnitString } ?? .pcs
        
        Task {
            if let existingIngredient = ingredientToEdit {
                // Update existing
                var updated = existingIngredient
                updated.name = name
                updated.averageCost = cost
                updated.stockQuantity = stock
                updated.unit = unit
                await viewModel.updateIngredient(updated)
            } else {
                // Create new
                await viewModel.createIngredient(name: name, cost: cost, stock: stock, unit: unit)
            }
            
            await MainActor.run {
                dismiss(animated: true)
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
