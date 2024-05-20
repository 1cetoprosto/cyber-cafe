//
//  SaleDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit

class SaleDetailsViewController: UIViewController, UITextFieldDelegate {
    
    var viewModel: SaleDetailsViewModelType?
    var tableViewModel: SaleGoodListViewModelType?
    private var dateChanged: Bool = false
    
    let datePicker: UIDatePicker = {
        let picker = UIDatePicker(frame: CGRect(x: 0, y: 70, width: 100, height: 50))
        picker.datePickerMode = .date
        picker.locale = .current
        picker.contentHorizontalAlignment = .center
        picker.preferredDatePickerStyle = .automatic
        picker.addTarget(SaleDetailsViewController.self, action: #selector(datePickerChanged), for: .valueChanged)
        
        return picker
    }()

    let idSaleCell = "idSaleCell"
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SaleTableViewCell.self, forCellReuseIdentifier: idSaleCell)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
    let cashLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    let cashTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "0"
        textField.font = UIFont.systemFont(ofSize: 28)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }()
    
    let cardLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    let cardTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "0"
        textField.font = UIFont.systemFont(ofSize: 28)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }()
    
    let saleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.text = "0"
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    let typeTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "Choose type of donation"
        textField.font = UIFont.systemFont(ofSize: 20)
        textField.textColor = UIColor.Main.text
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }()
    
    lazy var saveButton: UIButton = {
        let button = DefaultButton()
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
        return button
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            guard let viewModel = viewModel else { return }
            if viewModel.sum == 0.0 {
                //SaleGoodListViewModel.deleteSalesGood(date: viewModel.date)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Donat for:"
        view.backgroundColor = UIColor.Main.background
        navigationController?.view.backgroundColor = UIColor.NavBar.background
        
        self.cashTextfield.delegate = self
        self.cardTextfield.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.center = view.center
        //pickerView.isHidden = true

        self.view.addSubview(pickerView)
        
        typeTextfield.inputView = pickerView
        
        setData()
        setConstraints()
    }
    
    fileprivate func setData() {
        if viewModel == nil {
            viewModel = SaleDetailsViewModel(model: DailySalesModel(id: "",
                                                                    date: Date(),
                                                                    incomeType: "",
                                                                    sum: 0.0,
                                                                    cash: 0.0,
                                                                    card: 0.0),
                                             isNewModel: true)
        }
        
        guard let viewModel = viewModel else { return }
        
        if viewModel.cash != 0 {
            cashTextfield.text = viewModel.cash.description
        }
        if viewModel.card != 0 {
            cardTextfield.text = viewModel.card.description
        }
        if viewModel.sum != 0 {
            saleLabel.text = viewModel.sum.description
        }
        cashLabel.text = viewModel.cashLabel
        cardLabel.text = viewModel.cardLabel
        datePicker.date = viewModel.date
        typeTextfield.text = viewModel.incomeType
        
            if tableViewModel == nil {
                tableViewModel = SaleGoodListViewModel()
                tableViewModel?.getSaleGoods(date: viewModel.date) {
                    self.tableView.reloadData()
                }
            }
    }

    // MARK: - Method
    @objc func saveAction(param: UIButton?) {
        guard let viewModel = viewModel else { return }
        
        viewModel.isExist(date: datePicker.date, type: typeTextfield.text ?? "Income type") { [weak self] exists in
            guard let self = self else { return }
            
            if exists {
                self.handleExistingData()
            } else {
                self.saveAndNavigate()
            }
        }
    }

    private func handleExistingData() {
        if dateChanged {
            let alert = UIAlertController(title: "Warning!",
                                          message: "Data for the selected date already exists. Open and edit them.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            present(alert, animated: true)
        }
    }

    private func saveAndNavigate() {
        saveModels()
        navigationController?.popToRootViewController(animated: true)
    }


    @objc func cancelAction(param: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }

    // handle stepper value change action
    @objc func stepperValueChanged(_ stepper: UIStepper) {

        let stepperValue = Int(stepper.value)
        let stepperTag = Int(stepper.tag)

        let indexPath = IndexPath(row: stepperTag, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? SaleTableViewCell {
            cell.quantityLabel.text = String(stepperValue)
            tableViewModel?.setQuantity(tag: stepperTag, quantity: stepperValue)
        }
        saleLabel.text = tableViewModel?.totalSum()
    }
    
    @objc func datePickerChanged (_ sender: UIDatePicker ) {
        dateChanged = true
        //TODO: need calculate totalSum
        saleLabel.text = tableViewModel?.totalSum()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func saveModels() {
        guard let viewModel = self.viewModel else { return }
        
        if viewModel.isNewModel {
            viewModel.saveSales(date: datePicker.date,
                                incomeType: typeTextfield.text,
                                cash: cashTextfield.text,
                                card: cardTextfield.text,
                                sum: saleLabel.text)
        } else {
            viewModel.updateSales(date: datePicker.date,
                                  incomeType: typeTextfield.text,
                                  cash: cashTextfield.text,
                                  card: cardTextfield.text,
                                  sum: saleLabel.text)
        }
        
        //if viewModel.typeOfDonation == "Sunday service" {
            guard let tableViewModel = self.tableViewModel else { return }
            if viewModel.isNewModel {
                tableViewModel.saveSalesGood(date: datePicker.date)
            } else {
                tableViewModel.updateSalesGood(date: datePicker.date)
            }
        //}
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SaleDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewModel = tableViewModel else { return 0 }
        return tableViewModel.numberOfRowInSection(for: section)//salesGoodsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSaleCell, for: indexPath) as? SaleTableViewCell
        
        guard let tableViewCell = cell,
        let tableViewModel = tableViewModel else { return UITableViewCell() }
        
        let cellViewModel = tableViewModel.cellViewModel(for: indexPath)
        tableViewCell.viewModel = cellViewModel
        tableViewCell.goodStepper.addTarget(self, action: #selector(self.stepperValueChanged(_:)), for: .valueChanged)
        
        return tableViewCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate
extension SaleDetailsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Sets the number of rows in the picker view
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let viewModel = viewModel else { return 0 }
        return viewModel.numberOfRowsInComponent(component: component)
    }
    
    // This function sets the text of the picker view to the content of the "salutations" array
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let viewModel = viewModel else { return nil }
        return viewModel.titleForRow(row: row, component: component)
    }

    // When user selects an option, this function will set the text of the text field to reflect
    // the selected option.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let viewModel = viewModel else { return }
        //viewModel.setTypeOfDonation(row: row, component: component)
        guard let typeOfDonation = viewModel.titleForRow(row: row, component: component) else { return }
        typeTextfield.text = typeOfDonation
        view.endEditing(true)
        
//        if typeOfDonation != "Sunday service" {
//            //SaleGoodListViewModel.deleteSalesGood(date: viewModel.date)
//            tableViewModel = SaleGoodListViewModel()
//                self.tableView.reloadData()
//        }
//        if typeOfDonation == "Sunday service" {
            if tableViewModel == nil {
                tableViewModel = SaleGoodListViewModel()
                tableViewModel?.getSaleGoods(date: viewModel.date) {
                    self.tableView.reloadData()
                }
            }
//        }
        self.tableView.reloadData()
    }
}

// MARK: - Constraints
extension SaleDetailsViewController {
    func setConstraints() {

        let cashStackView = UIStackView(arrangedSubviews: [cashLabel, cashTextfield],
                                        axis: .horizontal,
                                        spacing: 5,
                                        distribution: .equalSpacing)
        view.addSubview(cashStackView)
        
        let cardStackView = UIStackView(arrangedSubviews: [cardLabel, cardTextfield],
                                        axis: .horizontal,
                                        spacing: 5,
                                        distribution: .equalSpacing)
        view.addSubview(cardStackView)
        
        let donatStackView = UIStackView(arrangedSubviews: [cashStackView, cardStackView],
                                        axis: .vertical,
                                        spacing: 5,
                                        distribution: .equalSpacing)
        view.addSubview(donatStackView)

        let moneyStackView = UIStackView(arrangedSubviews: [donatStackView, saleLabel],
                                         axis: .horizontal,
                                         spacing: 10,
                                         distribution: .fillEqually)
        view.addSubview(moneyStackView)

        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        let mainStackView = UIStackView(arrangedSubviews: [datePicker, tableView, typeTextfield, moneyStackView, saveButton],
                                        axis: .vertical,
                                        spacing: 10,
                                        distribution: .fill)
        view.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}

