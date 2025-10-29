//
//  OrderDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit

class OrderDetailsViewController: UIViewController, UITextFieldDelegate {

  var viewModel: OrderDetailsViewModelType?
  var tableViewModel: ProductListViewModelType?
  var onSave: (() -> Void)?
  private var dateChanged: Bool = false

  let datePicker: UIDatePicker = {
    let picker = UIDatePicker(frame: CGRect(x: 0, y: 70, width: 100, height: 50))
    picker.datePickerMode = .date
    picker.locale = .current
    picker.contentHorizontalAlignment = .center
    picker.preferredDatePickerStyle = .automatic
    picker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)

    return picker
  }()

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(OrderTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.orderCell)
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

  let orderLabel: UILabel = {
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
    textField.placeholder = R.string.global.chooseType()
    textField.font = UIFont.systemFont(ofSize: 20)
    textField.textColor = UIColor.Main.text
    textField.translatesAutoresizingMaskIntoConstraints = false

    return textField
  }()

  lazy var saveButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
    return button
  }()

  private let toolbar: UIToolbar = {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()
    let doneButton = UIBarButtonItem(
      barButtonSystemItem: .done, target: self, action: #selector(donePicker))
    toolbar.setItems([doneButton], animated: false)
    toolbar.isUserInteractionEnabled = true
    return toolbar
  }()

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    if self.isMovingFromParent {
      guard let viewModel = viewModel else { return }
      if viewModel.sum == 0.0 {
        //ProductListViewModel.deleteOrder(date: viewModel.date)
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = R.string.global.order()
    view.backgroundColor = UIColor.Main.background
    navigationController?.view.backgroundColor = UIColor.NavBar.background

    self.cashTextfield.delegate = self
    self.cardTextfield.delegate = self

    let pickerView = UIPickerView()
    pickerView.delegate = self
    pickerView.dataSource = self
    pickerView.center = view.center

    typeTextfield.inputView = pickerView
    typeTextfield.inputAccessoryView = toolbar

    setData()
    setConstraints()

    verifyRequiredData {

    }
  }

  fileprivate func setData() {
    if viewModel == nil {
      // Пошукати модель за сьогоднішній день, якщо немає створити пусту
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

    if viewModel.cash != 0 {
      cashTextfield.text = viewModel.cash.description
    }
    if viewModel.card != 0 {
      cardTextfield.text = viewModel.card.description
    }
    if viewModel.sum != 0 {
      orderLabel.text = viewModel.sum.description
    }
    cashLabel.text = viewModel.cashLabel
    cardLabel.text = viewModel.cardLabel
    datePicker.date = viewModel.date
    typeTextfield.text = viewModel.type

    if tableViewModel == nil {
      tableViewModel = ProductListViewModel()
      tableViewModel?.getProducts(withIdOrder: viewModel.id) {
        self.tableView.reloadData()
      }
    }
  }

  private func verifyRequiredData(completion: @escaping () -> Void) {
    viewModel?.verifyRequiredData { isDataAvailable in
      if isDataAvailable {
        completion()
      } else {
        let alert = UIAlertController(
          title: R.string.global.error(),
          message: R.string.global.requiredDataIsMissingInUserSettings(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: R.string.global.actionOk(), style: .default))
        self.present(alert, animated: true)
      }
    }
  }

  // MARK: - Method
  @objc func saveAction(param: UIButton?) {
    guard let viewModel = viewModel else { return }
    saveAndNavigate()
  }

  private func handleExistingData() {
    if dateChanged {
      let alert = UIAlertController(
        title: R.string.global.warning(),
        message: R.string.global.dataForTheSelectedDateAlreadyExistsOpenAndEditThem(),
        preferredStyle: .alert)
      let ok = UIAlertAction(title: R.string.global.actionOk(), style: .default)
      alert.addAction(ok)
      present(alert, animated: true)
    }
  }

  private func saveAndNavigate() {
    saveModels { [weak self] in
      self?.onSave?()
      self?.navigationController?.popToRootViewController(animated: true)
    }
  }

  @objc func cancelAction(param: UIButton) {
    navigationController?.popToRootViewController(animated: true)
  }

  // handle stepper value change action
  @objc func stepperValueChanged(_ stepper: UIStepper) {

    let stepperValue = Int(stepper.value)
    let stepperTag = Int(stepper.tag)

    let indexPath = IndexPath(row: stepperTag, section: 0)
    if let cell = tableView.cellForRow(at: indexPath) as? OrderTableViewCell {
      cell.quantityLabel.text = String(stepperValue)
      tableViewModel?.setQuantity(tag: stepperTag, quantity: stepperValue)
    }
    orderLabel.text = tableViewModel?.totalSum()
  }

  @objc func datePickerChanged(_ sender: UIDatePicker) {
    dateChanged = true
    //TODO: need calculate totalSum
    orderLabel.text = tableViewModel?.totalSum()
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
  }

  @objc private func donePicker() {
    view.endEditing(true)
  }

  func saveModels(completion: @escaping () -> Void) {
    guard let viewModel = self.viewModel else { return }

    if viewModel.isNewModel {
      viewModel.saveOrders(
        id: "",
        date: datePicker.date,
        type: typeTextfield.text,
        cash: cashTextfield.text,
        card: cardTextfield.text,
        sum: orderLabel.text
      ) {
        completion()
      }

    } else {
      viewModel.updateOrders(
        id: viewModel.id,
        date: datePicker.date,
        type: typeTextfield.text,
        cash: cashTextfield.text,
        card: cardTextfield.text,
        sum: orderLabel.text
      ) {
        completion()
      }
    }

    guard let tableViewModel = self.tableViewModel else { return }
    if viewModel.isNewModel {
      tableViewModel.saveOrder(withOrderId: viewModel.id, date: datePicker.date)
    } else {
      tableViewModel.updateOrder(date: datePicker.date)
    }
  }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension OrderDetailsViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let tableViewModel = tableViewModel else { return 0 }
    return tableViewModel.numberOfRowInSection(for: section)  //ordersProductsArray.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.orderCell, for: indexPath)
      as? OrderTableViewCell

    guard let tableViewCell = cell,
      let tableViewModel = tableViewModel
    else { return UITableViewCell() }

    let cellViewModel = tableViewModel.cellViewModel(for: indexPath)
    tableViewCell.viewModel = cellViewModel
    tableViewCell.productStepper.addTarget(
      self, action: #selector(self.stepperValueChanged(_:)), for: .valueChanged)

    return tableViewCell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate
extension OrderDetailsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  // Sets the number of rows in the picker view
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    guard let viewModel = viewModel else { return 0 }
    return viewModel.numberOfRowsInComponent(component: component)
  }

  // This function sets the text of the picker view to the content of the "salutations" array
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
    -> String?
  {
    guard let viewModel = viewModel else { return nil }
    return viewModel.titleForRow(row: row, component: component)
  }

  // When user selects an option, this function will set the text of the text field to reflect
  // the selected option.
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard let viewModel = viewModel else { return }
    //viewModel.setType(row: row, component: component)
    guard let type = viewModel.titleForRow(row: row, component: component) else { return }
    typeTextfield.text = type
    view.endEditing(true)

    //        if type != "Sunday service" {
    //            //ProductListViewModel.deleteOrder(date: viewModel.date)
    //            tableViewModel = ProductListViewModel()
    //                self.tableView.reloadData()
    //        }
    //        if type == "Sunday service" {
    //            if tableViewModel == nil {
    //                tableViewModel = ProductListViewModel()
    //                tableViewModel?.getProducts(withIdOrder: viewModel.id) {
    //                    self.tableView.reloadData()
    //                }
    //            }
    //        }
    //        self.tableView.reloadData()
  }
}

// MARK: - Constraints
extension OrderDetailsViewController {
  func setConstraints() {

    let cashStackView = UIStackView(
      arrangedSubviews: [cashLabel, cashTextfield],
      axis: .horizontal,
      spacing: 5,
      distribution: .equalSpacing)
    view.addSubview(cashStackView)

    let cardStackView = UIStackView(
      arrangedSubviews: [cardLabel, cardTextfield],
      axis: .horizontal,
      spacing: 5,
      distribution: .equalSpacing)
    view.addSubview(cardStackView)

    let cashCardStackView = UIStackView(
      arrangedSubviews: [cashStackView, cardStackView],
      axis: .vertical,
      spacing: 5,
      distribution: .equalSpacing)
    view.addSubview(cashCardStackView)

    let moneyStackView = UIStackView(
      arrangedSubviews: [cashCardStackView, orderLabel],
      axis: .horizontal,
      spacing: 10,
      distribution: .fillEqually)
    view.addSubview(moneyStackView)

    NSLayoutConstraint.activate([
      saveButton.heightAnchor.constraint(equalToConstant: 50)
    ])

    let mainStackView = UIStackView(
      arrangedSubviews: [datePicker, tableView, typeTextfield, moneyStackView, saveButton],
      axis: .vertical,
      spacing: 10,
      distribution: .fill)
    view.addSubview(mainStackView)

    NSLayoutConstraint.activate([
      mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      mainStackView.leadingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
      mainStackView.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
      mainStackView.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
    ])
  }
}
