//
//  CreatePurchaseViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import UIKit

class CreatePurchaseViewController: UIViewController {
    
    private let viewModel: CreatePurchaseViewModelType
    private var ingredients: [IngredientModel] = []
    private var selectedIngredientId: String?
    
    // MARK: - UI Elements
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var ingredientTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Select Ingredient"
        tf.borderStyle = .roundedRect
        tf.delegate = self
        return tf
    }()
    
    private lazy var quantityTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Quantity"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        return tf
    }()
    
    private lazy var priceTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Price per Unit"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .decimalPad
        return tf
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        return picker
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Purchase", for: .normal)
        button.backgroundColor = UIColor.Button.background
        button.tintColor = UIColor.Button.title
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()
    
    private let ingredientPicker = UIPickerView()
    
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
        setupPicker()
        loadIngredients()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "New Purchase"
        view.backgroundColor = UIColor.Main.background
        
        view.addSubview(stackView)
        stackView.addArrangedSubview(datePicker)
        stackView.addArrangedSubview(ingredientTextField)
        stackView.addArrangedSubview(quantityTextField)
        stackView.addArrangedSubview(priceTextField)
        stackView.addArrangedSubview(saveButton)
        stackView.addArrangedSubview(UIView()) // Spacer
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupPicker() {
        ingredientPicker.delegate = self
        ingredientPicker.dataSource = self
        ingredientTextField.inputView = ingredientPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePicker))
        toolbar.setItems([doneButton], animated: false)
        ingredientTextField.inputAccessoryView = toolbar
    }
    
    private func loadIngredients() {
        viewModel.fetchIngredients { [weak self] ingredients in
            self?.ingredients = ingredients
            self?.ingredientPicker.reloadAllComponents()
        }
    }
    
    // MARK: - Actions
    
    @objc private func donePicker() {
        ingredientTextField.resignFirstResponder()
        let row = ingredientPicker.selectedRow(inComponent: 0)
        if row < ingredients.count {
            let ingredient = ingredients[row]
            ingredientTextField.text = ingredient.name
            selectedIngredientId = ingredient.id
        }
    }
    
    @objc private func saveTapped() {
        guard let ingredientId = selectedIngredientId else {
            showAlert(message: "Please select an ingredient")
            return
        }
        
        guard let qtyString = quantityTextField.text, let qty = Double(qtyString) else {
            showAlert(message: "Invalid quantity")
            return
        }
        
        guard let priceString = priceTextField.text, let price = Double(priceString) else {
            showAlert(message: "Invalid price")
            return
        }
        
        viewModel.savePurchase(date: datePicker.date, ingredientId: ingredientId, quantity: qty, price: price) { [weak self] success, errorMsg in
            DispatchQueue.main.async {
                if success {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    self?.showAlert(message: errorMsg ?? "Unknown error")
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Picker Delegate & DataSource
extension CreatePurchaseViewController: UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ingredients.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ingredients[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < ingredients.count else { return }
        let ingredient = ingredients[row]
        ingredientTextField.text = ingredient.name
        selectedIngredientId = ingredient.id
    }
}
