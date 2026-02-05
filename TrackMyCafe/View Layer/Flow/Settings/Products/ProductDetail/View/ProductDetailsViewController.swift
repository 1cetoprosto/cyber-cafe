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

    private lazy var recipeTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RecipeItemTableViewCell.self, forCellReuseIdentifier: "RecipeCell")
        return tableView
    }()

    private var recipeTableViewHeightConstraint: NSLayoutConstraint?

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

        updateRecipeUI()
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
        mainStackView.addArrangedSubview(recipeTableView)
        mainStackView.addArrangedSubview(addIngredientButton)
    }

    private func updateRecipeUI() {
        recipeTableView.reloadData()
        recipeTableView.layoutIfNeeded()
        recipeTableViewHeightConstraint?.constant = recipeTableView.contentSize.height
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

        recipeTableViewHeightConstraint = recipeTableView.heightAnchor.constraint(equalToConstant: 0)
        recipeTableViewHeightConstraint?.isActive = true

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

        if ingredients.isEmpty {
            let alert = UIAlertController(
                title: R.string.global.noIngredients(),
                message: R.string.global.pleaseAddIngredients(),
                preferredStyle: .alert)

            alert.addAction(
                UIAlertAction(title: R.string.global.actionOk(), style: .default, handler: nil))
            alert.addAction(
                UIAlertAction(title: R.string.global.actionGoToSettings(), style: .default) {
                    [weak self] _ in
                    self?.navigationController?.popToRootViewController(animated: true)
                })

            present(alert, animated: true, completion: nil)
            return
        }

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
        let message = R.string.global.enterQuantityPerUnit(ingredient.unit.localizedName)
        let alert = UIAlertController(title: ingredient.name, message: message, preferredStyle: .alert)

        alert.addTextField { [weak self] textField in
            textField.keyboardType = UIKeyboardType.decimalPad
            textField.placeholder = "0.0"
            textField.delegate = self
        }

        alert.addAction(
            UIAlertAction(
                title: R.string.global.cancel(), style: .cancel,
                handler: nil))
        alert.addAction(
            UIAlertAction(
                title: R.string.global.add(), style: .default
            ) {
                [weak self] _ in
                guard let self = self else { return }
                guard let text = alert.textFields?.first?.text,
                    let quantity = Double(text.replacingOccurrences(of: ",", with: "."))
                else { return }

                if self.viewModel.hasIngredient(ingredient) {
                    let overwriteAlert = UIAlertController(
                        title: R.string.global.ingredientAlreadyExists(),
                        message: R.string.global.overwriteIngredientMessage(),
                        preferredStyle: .alert
                    )
                    overwriteAlert.addAction(
                        UIAlertAction(title: R.string.global.yes(), style: .destructive) { _ in
                            self.viewModel.addRecipeItem(
                                ingredient: ingredient, quantity: quantity, overwrite: true)
                        })
                    overwriteAlert.addAction(
                        UIAlertAction(title: R.string.global.no(), style: .cancel, handler: nil))
                    self.present(overwriteAlert, animated: true)
                } else {
                    self.viewModel.addRecipeItem(ingredient: ingredient, quantity: quantity, overwrite: false)
                }
            })

        present(alert, animated: true, completion: nil)
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

    func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Allow navigation and deletion
        if string.isEmpty { return true }

        // If it's one of the main input containers, don't restrict (unless we want to, but currently they have their own logic or delegates might not be fully wired for restriction here)
        // Check if it's the alert text field. Since we don't have a direct reference to the alert text field here easily without storing it,
        // we can check if it is NOT one of our known properties.
        if textField == nameInputContainer.textFieldReference
            || textField == priceInputContainer.textFieldReference
        {
            return true
        }

        // For the alert text field (ingredient quantity), restrict to numbers and one decimal separator
        let currentText = textField.text ?? ""
        let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)

        // Use a regex to validate double/float format
        // ^[0-9]*([.,][0-9]*)?$ matches empty, integers, decimals with dot or comma
        let pattern = "^[0-9]*([.,][0-9]*)?$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: replacementText.count)
            if regex.firstMatch(in: replacementText, options: [], range: range) == nil {
                return false
            }
        }

        return true
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension ProductDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentRecipe.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
                as? RecipeItemTableViewCell
        else {
            return UITableViewCell()
        }

        let item = viewModel.currentRecipe[indexPath.row]
        cell.configure(item: item)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(
        _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            viewModel.removeRecipeItem(at: indexPath.row)
        }
    }
}
