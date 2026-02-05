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
        button.setTitle(R.string.global.add(), for: .normal)
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    init(viewModel: IngredientListViewModelType) {
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
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.newIngredient()
        
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(mainStackView)
        
        // Add sections to stack
        addSection(input: nameInputContainer, explanation: nameExplanationLabel)
        addSection(input: costInputContainer, explanation: costExplanationLabel)
        addSection(input: stockInputContainer, explanation: stockExplanationLabel)
        addSection(input: unitInputContainer, explanation: unitExplanationLabel)
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
        
        mainStackView.edgesToSuperview(insets: .uniform(UIConstants.standardPadding))
        mainStackView.width(to: scrollView, offset: -2 * UIConstants.standardPadding)
        
        saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        saveButton.height(UIConstants.buttonHeight)
        saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UIConstants.standardPadding)
        saveButtonBottomConstraint.isActive = true
    }
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification,
            object: nil)
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
            await viewModel.createIngredient(name: name, cost: cost, stock: stock, unit: unit)
            await MainActor.run {
                dismiss(animated: true)
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize =
            (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        {
            saveButtonBottomConstraint.constant = -keyboardSize.height - UIConstants.standardPadding
            view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        saveButtonBottomConstraint.constant = -UIConstants.standardPadding
        view.layoutIfNeeded()
    }
}
