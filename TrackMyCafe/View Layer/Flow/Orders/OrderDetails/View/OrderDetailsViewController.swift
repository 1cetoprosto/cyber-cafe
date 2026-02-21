//
//  OrderDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import TinyConstraints
import UIKit

class OrderDetailsViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    var viewModel: OrderDetailsViewModelType?
    var onSave: (() -> Void)?
    
    private var dateChanged: Bool = false
    private var saveButtonBottomConstraint: NSLayoutConstraint!
    private var tableViewHeightConstraint: Constraint?
    private var collectionViewHeightConstraint: Constraint?
    private var isGridView: Bool = false
    
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
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(OrderTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.orderCell)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false // Disable scroll to avoid conflict with ScrollView
        return tableView
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = UIConstants.standardPadding
        layout.minimumLineSpacing = UIConstants.standardPadding
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.Main.background
        collectionView.register(OrderCollectionViewCell.self, forCellWithReuseIdentifier: "OrderCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false // Disable scroll to avoid conflict with ScrollView
        collectionView.isHidden = true // Initially hidden
        return collectionView
    }()
    
    private lazy var cashInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: "",
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: "0"
        )
        return container
    }()
    
    private lazy var cardInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: "",
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: "0"
        )
        return container
    }()
    
    private let orderLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.text = "0"
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.title3)
        return label
    }()
    
    private let totalTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.title3)
        return label
    }()
    
    private lazy var typeInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.type(),
            inputType: .text(keyboardType: .default),
            isEditable: true,
            placeholder: R.string.global.chooseType()
        )
        return container
    }()
    
    private lazy var saveButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.save(), for: .normal)
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        return button
    }()
    
    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePicker))
        toolbar.setItems([doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        return toolbar
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OnboardingManager.shared.startIfNeeded(for: .orderDetails, on: self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = R.string.global.order()
        view.backgroundColor = UIColor.Main.background
        navigationController?.view.backgroundColor = UIColor.NavBar.background
        
        // Add toggle button
        let toggleImage = UIImage(systemName: "square.grid.2x2")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: toggleImage, style: .plain, target: self, action: #selector(toggleViewMode))
        
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(mainStackView)
        
        setupAccessibility()
        setupInputs()
        setupPicker()
        setupConstraints()
        setupKeyboardHandling()
        
        // Observers
        dateInputContainer.onDateChange = { [weak self] _ in
            self?.dateChanged = true
            self?.updateTotalSumLabel()
        }
    }
    
    private func setupAccessibility() {
        dateInputContainer.accessibilityIdentifier = "dateInput"
        typeInputContainer.accessibilityIdentifier = "typeInput"
        tableView.accessibilityIdentifier = "productsTable"
        orderLabel.accessibilityIdentifier = "totalsRow"
        cashInputContainer.accessibilityIdentifier = "cashInput"
        cardInputContainer.accessibilityIdentifier = "cardInput"
        saveButton.accessibilityIdentifier = "saveButton"
    }
    
    private func setupInputs() {
        cashInputContainer.setDelegate(self)
        cardInputContainer.setDelegate(self)
        cashInputContainer.enableNumericInput(maxFractionDigits: 2)
        cardInputContainer.enableNumericInput(maxFractionDigits: 2)
        
        let currencySymbol = RequestManager.shared.settings?.currencySymbol
        ?? ((Locale.current.languageCode == "uk") ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)
        
        cashInputContainer.enableCurrencySuffix(symbol: currencySymbol)
        cardInputContainer.enableCurrencySuffix(symbol: currencySymbol)
        
        cashInputContainer.setReturnKeyType(.done)
        cardInputContainer.setReturnKeyType(.done)
        typeInputContainer.setReturnKeyType(.done)
        
        cashInputContainer.textFieldReference?.textAlignment = .right
        cardInputContainer.textFieldReference?.textAlignment = .right
    }
    
    private func setupPicker() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        typeInputContainer.textFieldReference?.inputView = pickerView
        typeInputContainer.textFieldReference?.inputAccessoryView = toolbar
    }
    
    private func setupData() {
        if viewModel == nil {
            viewModel = OrderDetailsViewModel(
                model: OrderModel(
                    id: "",
                    date: Date(),
                    type: "",
                    sum: 0.0,
                    cash: 0.0,
                    card: 0.0),
                isNewModel: true)
        }
        
        guard let viewModel = viewModel else { return }
        
        if viewModel.cash != 0 { cashInputContainer.text = viewModel.cash.decimalFormat }
        if viewModel.card != 0 { cardInputContainer.text = viewModel.card.decimalFormat }
        if viewModel.sum != 0 { orderLabel.text = viewModel.sum.currency }
        
        cashInputContainer.configure(labelText: viewModel.cashLabel)
        cardInputContainer.configure(labelText: viewModel.cardLabel)
        totalTitleLabel.text = viewModel.orderLabel
        totalTitleLabel.isHidden = false
        dateInputContainer.date = viewModel.date
        typeInputContainer.text = viewModel.type
        
        if (typeInputContainer.text?.isEmpty ?? true) && viewModel.isNewModel {
            DomainDatabaseService.shared.fetchTypes { [weak self] types in
                if let def = types.first(where: { $0.isDefault }) {
                    DispatchQueue.main.async { self?.typeInputContainer.text = def.name }
                }
            }
        }
        
        viewModel.loadProducts { [weak self] in
            self?.tableView.reloadData()
            self?.collectionView.reloadData()
            self?.updateTableHeight()
            self?.updateCollectionHeight()
            self?.updateTotalSumLabel()
        }
        
        verifyRequiredData()
    }
    
    private func verifyRequiredData() {
        viewModel?.verifyRequiredData { [weak self] isDataAvailable in
            if !isDataAvailable {
                let alert = UIAlertController(
                    title: R.string.global.error(),
                    message: R.string.global.requiredDataIsMissingInUserSettings(),
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: R.string.global.actionOk(), style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func updateTableHeight() {
        tableView.layoutIfNeeded()
        let height = tableView.contentSize.height
        tableViewHeightConstraint?.constant = max(height, 50)
    }
    
    private func updateCollectionHeight() {
        collectionView.layoutIfNeeded()
        let height = collectionView.contentSize.height
        collectionViewHeightConstraint?.constant = max(height, 50)
    }
    
    private func updateTotalSumLabel() {
        orderLabel.text = viewModel?.productsViewModel.totalSum()
    }
    
    // MARK: - Actions
    @objc private func toggleViewMode() {
        isGridView.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.tableView.isHidden = self.isGridView
            self.collectionView.isHidden = !self.isGridView
            self.mainStackView.layoutIfNeeded()
        }
        
        let iconName = isGridView ? "list.bullet" : "square.grid.2x2"
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: iconName)
        
        if isGridView {
            updateCollectionHeight()
        } else {
            updateTableHeight()
        }
    }
    
    @objc func saveAction() {
        guard let viewModel = viewModel else { return }
        
        let date = dateInputContainer.date ?? Date()
        let type = typeInputContainer.text
        let cash = cashInputContainer.text
        let card = cardInputContainer.text
        
        viewModel.save(date: date, type: type, cash: cash, card: card, ignoreStockWarning: false) { [weak self] result in
            self?.handleSaveResult(result)
        }
    }
    
    private func handleSaveResult(_ result: Result<Void, OrderSaveError>) {
        switch result {
        case .success:
            self.onSave?()
            self.navigationController?.popToRootViewController(animated: true)
            
        case .failure(let error):
            switch error {
            case .stockValidationFailed(let warnings):
                self.showStockWarning(warnings)
            case .saveFailed, .fetchFailed:
                let alert = UIAlertController(title: "Error", message: "Failed to save order", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    private func showStockWarning(_ warnings: [StockWarning]) {
        let message = warnings.map { warning in
            let shortage = warning.requiredQty - warning.currentStock
            return "\(warning.ingredientName): Need \(String(format: "%.2f", shortage)) more"
        }.joined(separator: "\n")
        
        let alert = UIAlertController(
            title: "Stock Warning",
            message: "Not enough stock for:\n" + message + "\nProceed anyway?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Proceed", style: .destructive, handler: { [weak self] _ in
            guard let self = self, let viewModel = self.viewModel else { return }
            
            let date = self.dateInputContainer.date ?? Date()
            let type = self.typeInputContainer.text
            let cash = self.cashInputContainer.text
            let card = self.cardInputContainer.text
            
            viewModel.save(date: date, type: type, cash: cash, card: card, ignoreStockWarning: true) { [weak self] result in
                self?.handleSaveResult(result)
            }
        }))
        self.present(alert, animated: true)
    }
    
    @objc func stepperValueChanged(_ stepper: UIStepper) {
        let stepperValue = Int(stepper.value)
        let stepperTag = Int(stepper.tag)
        
        // Update ViewModel
        viewModel?.productsViewModel.setQuantity(tag: stepperTag, quantity: stepperValue)
        updateTotalSumLabel()
        
        // Reload visible cells in both views to sync UI
        // Ideally we should bind this, but simple reload works for now
        // Or specific cell reload
        
        if isGridView {
            // Update corresponding table cell (if needed for later)
            // Actually reloading data might be expensive.
            // Let's just update the visible cell if possible, or reloadData
            // Since we are changing ONE item, let's try to update just that item in the OTHER view.
            
            // However, since one view is hidden, we can just reload it when we switch back.
            // But to be safe, let's reload both for now or just the visible one.
            // Wait, we need to update the CURRENT view's label immediately (which stepper handles mostly, but label needs update)
            
            let indexPath = IndexPath(item: stepperTag, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? OrderCollectionViewCell {
                cell.quantityLabel.text = String(stepperValue)
            }
        } else {
            let indexPath = IndexPath(row: stepperTag, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? OrderTableViewCell {
                cell.quantityLabel.text = String(stepperValue)
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func donePicker() {
        view.endEditing(true)
    }
    
    // MARK: - TextField Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let current = textField.text ?? ""
        if current == "0" || current == "0,0" || current == "0.0" { textField.text = "" }
    }
}

// MARK: - TableView
extension OrderDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.productsViewModel.numberOfRowInSection(for: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.orderCell, for: indexPath) as? OrderTableViewCell,
              let cellViewModel = viewModel?.productsViewModel.cellViewModel(for: indexPath)
        else { return UITableViewCell() }
        
        cell.viewModel = cellViewModel
        cell.productStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - CollectionView
extension OrderDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.productsViewModel.numberOfRowInSection(for: section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OrderCollectionViewCell", for: indexPath) as? OrderCollectionViewCell,
              let cellViewModel = viewModel?.productsViewModel.cellViewModel(for: indexPath)
        else { return UICollectionViewCell() }
        
        cell.viewModel = cellViewModel
        cell.productStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = UIConstants.standardPadding
        // 2 columns: (Width - padding * 3) / 2
        // Assuming standardPadding is spacing between items and edges
        let availableWidth = collectionView.frame.width - (padding * 3)
        let width = availableWidth / 2
        return CGSize(width: width, height: 140)
    }
}

// MARK: - PickerView
extension OrderDetailsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel?.numberOfRowsInComponent(component: component) ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel?.titleForRow(row: row, component: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let type = viewModel?.titleForRow(row: row, component: component) else { return }
        typeInputContainer.text = type
        view.endEditing(true)
    }
}

// MARK: - Constraints
extension OrderDetailsViewController {
    private func setupConstraints() {
        scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)
        
        mainStackView.edgesToSuperview(insets: .init(top: UIConstants.largeSpacing, left: UIConstants.standardPadding, bottom: UIConstants.largeSpacing, right: UIConstants.standardPadding))
        mainStackView.width(to: scrollView, offset: -2 * UIConstants.standardPadding)
        
        let containerHeight = UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding
        
        dateInputContainer.height(containerHeight)
        typeInputContainer.height(containerHeight)
        cashInputContainer.height(containerHeight)
        cardInputContainer.height(containerHeight)
        
        // TableView dynamic height
        tableViewHeightConstraint = tableView.height(300)
        
        // CollectionView dynamic height
        collectionViewHeightConstraint = collectionView.height(300)
        
        saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        saveButton.height(UIConstants.buttonHeight)
        saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -UIConstants.standardPadding)
        saveButtonBottomConstraint.isActive = true
        
        let cashCardStackView = UIStackView(arrangedSubviews: [cashInputContainer, cardInputContainer], axis: .horizontal, spacing: UIConstants.standardPadding, distribution: .fillEqually)
        
        let dateTypeStackView = UIStackView(arrangedSubviews: [dateInputContainer, typeInputContainer], axis: .horizontal, spacing: UIConstants.standardPadding, distribution: .fillEqually)
        
        let totalStackView = UIStackView(arrangedSubviews: [totalTitleLabel, orderLabel], axis: .horizontal, spacing: UIConstants.smallSpacing, distribution: .fill)
        
        mainStackView.addArrangedSubview(dateTypeStackView)
        mainStackView.addArrangedSubview(tableView)
        mainStackView.addArrangedSubview(collectionView) // Added CollectionView
        mainStackView.addArrangedSubview(totalStackView)
        mainStackView.addArrangedSubview(cashCardStackView)
    }
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        if let cashTF = cashInputContainer.textFieldReference { addDoneButtonToTextField(cashTF) }
        if let cardTF = cardInputContainer.textFieldReference { addDoneButtonToTextField(cardTF) }
    }
    
    private func addDoneButtonToTextField(_ textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: R.string.global.actionOk(), style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
    }
}
