//
//  OrderDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import TinyConstraints
import UIKit

class OrderDetailsViewController: UIViewController, UITextFieldDelegate {

  var viewModel: OrderDetailsViewModelType?
  var tableViewModel: ProductListViewModelType?
  var onSave: (() -> Void)?
  private var dateChanged: Bool = false
  private var saveButtonBottomConstraint: NSLayoutConstraint!

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

    return tableView
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

    view.addSubview(scrollView)
    view.addSubview(saveButton)
    scrollView.addSubview(mainStackView)

    cashInputContainer.setDelegate(self)
    cardInputContainer.setDelegate(self)
    cashInputContainer.enableNumericInput(maxFractionDigits: 2)
    cardInputContainer.enableNumericInput(maxFractionDigits: 2)
    let currencySymbol =
      RequestManager.shared.settings?.currencySymbol ?? DefaultValues.dollarSymbol
    cashInputContainer.enableCurrencySuffix(symbol: currencySymbol)
    cardInputContainer.enableCurrencySuffix(symbol: currencySymbol)
    cashInputContainer.setReturnKeyType(.done)
    cardInputContainer.setReturnKeyType(.done)
    typeInputContainer.setReturnKeyType(.done)
    cashInputContainer.textFieldReference?.textAlignment = .right
    cardInputContainer.textFieldReference?.textAlignment = .right

    let pickerView = UIPickerView()
    pickerView.delegate = self
    pickerView.dataSource = self
    pickerView.center = view.center

    typeInputContainer.textFieldReference?.inputView = pickerView
    typeInputContainer.textFieldReference?.inputAccessoryView = toolbar

    setData()
    setupConstraints()
    setupKeyboardHandling()

    dateInputContainer.onDateChange = { [weak self] _ in
      guard let self = self else { return }
      self.dateChanged = true
      self.orderLabel.text = self.tableViewModel?.totalSum()
    }

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
      cashInputContainer.text = viewModel.cash.description
    }
    if viewModel.card != 0 {
      cardInputContainer.text = viewModel.card.description
    }
    if viewModel.sum != 0 {
      orderLabel.text = viewModel.sum.currency
    }
    cashInputContainer.configure(labelText: viewModel.cashLabel)
    cardInputContainer.configure(labelText: viewModel.cardLabel)
    totalTitleLabel.text = viewModel.orderLabel
    totalTitleLabel.isHidden = false
    dateInputContainer.date = viewModel.date
    typeInputContainer.text = viewModel.type

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

  // @objc func cancelAction(param: UIButton) {
  //   navigationController?.popToRootViewController(animated: true)
  // }

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
    orderLabel.text = tableViewModel?.totalSum()
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return false
  }
  func textFieldDidBeginEditing(_ textField: UITextField) {
    let current = textField.text ?? ""
    if current == "0" || current == "0,0" || current == "0.0" { textField.text = "" }
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }

  @objc private func donePicker() {
    view.endEditing(true)
  }

  func saveModels(completion: @escaping () -> Void) {
    guard let viewModel = self.viewModel else { return }

    if viewModel.isNewModel {
      viewModel.saveOrders(
        id: "",
        date: dateInputContainer.date ?? Date(),
        type: typeInputContainer.text,
        cash: cashInputContainer.text,
        card: cardInputContainer.text,
        sum: orderLabel.text
      ) {
        completion()
      }

    } else {
      viewModel.updateOrders(
        id: viewModel.id,
        date: dateInputContainer.date ?? Date(),
        type: typeInputContainer.text,
        cash: cashInputContainer.text,
        card: cardInputContainer.text,
        sum: orderLabel.text
      ) {
        completion()
      }
    }

    guard let tableViewModel = self.tableViewModel else { return }
    if viewModel.isNewModel {
      tableViewModel.saveOrder(withOrderId: viewModel.id, date: dateInputContainer.date ?? Date())
    } else {
      tableViewModel.updateOrder(date: dateInputContainer.date ?? Date())
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
    typeInputContainer.text = type
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
  private func setupConstraints() {
    scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
    scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)

    mainStackView.edgesToSuperview(
      insets: .init(
        top: UIConstants.largeSpacing,
        left: UIConstants.standardPadding,
        bottom: UIConstants.largeSpacing,
        right: UIConstants.standardPadding
      )
    )
    mainStackView.width(to: scrollView, offset: -2 * UIConstants.standardPadding)

    let containerHeight =
      UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding
    dateInputContainer.height(containerHeight)
    typeInputContainer.height(containerHeight)
    cashInputContainer.height(containerHeight)
    cardInputContainer.height(containerHeight)
    tableView.height(300)

    saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
    saveButton.height(UIConstants.buttonHeight)
    saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(
      equalTo: view.keyboardLayoutGuide.topAnchor,
      constant: -UIConstants.standardPadding
    )
    saveButtonBottomConstraint.isActive = true

    let cashCardStackView = UIStackView(
      arrangedSubviews: [cashInputContainer, cardInputContainer],
      axis: .horizontal,
      spacing: UIConstants.standardPadding,
      distribution: .fillEqually
    )
    // let moneyStackView = UIStackView(
    //   arrangedSubviews: [cashCardStackView, orderLabel],
    //   axis: .horizontal,
    //   spacing: UIConstants.standardPadding,
    //   distribution: .fillEqually
    // )

    let dateTypeStackView = UIStackView(
      arrangedSubviews: [dateInputContainer, typeInputContainer],
      axis: .horizontal,
      spacing: UIConstants.standardPadding,
      distribution: .fillEqually
    )
    mainStackView.addArrangedSubview(dateTypeStackView)
    mainStackView.addArrangedSubview(tableView)
    let totalStackView = UIStackView(
      arrangedSubviews: [totalTitleLabel, orderLabel],
      axis: .horizontal,
      spacing: UIConstants.smallSpacing,
      distribution: .fill
    )
    mainStackView.addArrangedSubview(totalStackView)
    mainStackView.addArrangedSubview(cashCardStackView)
  }
}

extension OrderDetailsViewController {
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
    let doneButton = UIBarButtonItem(
      title: R.string.global.actionOk(),
      style: .done,
      target: self,
      action: #selector(dismissKeyboard)
    )
    toolbar.items = [flexSpace, doneButton]
    textField.inputAccessoryView = toolbar
  }
}
