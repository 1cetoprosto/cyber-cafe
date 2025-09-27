//
//  CostDetailsListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit

class CostDetailsListViewController: UIViewController {

  var viewModel: CostDetailsViewModelType?

  let costDateLabel: UILabel = {
    let label = UILabel(
      text: R.string.global.costDate(), font: UIFont.systemFont(ofSize: 20), aligment: .left)

    return label
  }()

  let costdatePiker: UIDatePicker = {
    let datePiker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    datePiker.datePickerMode = .date
    datePiker.contentHorizontalAlignment = .left
    datePiker.preferredDatePickerStyle = .automatic

    return datePiker
  }()

  let costNameLabel: UILabel = {
    let label = UILabel(
      text: R.string.global.costName(), font: UIFont.systemFont(ofSize: 20), aligment: .left)

    return label
  }()

  let costNameTextfield: UITextField = {
    let textField = UITextField(
      placeholder: R.string.global.costNamePlaceholder(), font: UIFont.systemFont(ofSize: 28))

    return textField
  }()

  let costSumLabel: UILabel = {
    let label = UILabel(
      text: R.string.global.costSum(), font: UIFont.systemFont(ofSize: 20), aligment: .left)

    return label
  }()

  let costSumTextfield: UITextField = {
    let textField = UITextField(
      placeholder: R.string.global.costSumPlaceholder(), font: UIFont.systemFont(ofSize: 28))

    return textField
  }()

  lazy var saveButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
    return button
  }()

  lazy var cancelButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.cancel(), for: .normal)
    button.addTarget(self, action: #selector(cancelAction(param:)), for: .touchUpInside)
    return button
  }()

  //    override func viewWillAppear(_ animated: Bool) {
  //        super.viewWillAppear(animated)
  //
  //        setData()
  //    }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = R.string.global.cost()
    view.backgroundColor = UIColor.Main.background
    navigationController?.view.backgroundColor = UIColor.NavBar.background

    setData()

    setConstraints()

  }

  // MARK: - Method
  fileprivate func setData() {
    if viewModel == nil {
      viewModel = CostDetailsViewModel(cost: CostModel(id: "", date: Date(), name: "", sum: 0))
    }

    guard let viewModel = viewModel else { return }
    if viewModel.costName != "" {
      costNameTextfield.text = viewModel.costName
    }
    if viewModel.costSum != "" {
      costSumTextfield.text = viewModel.costSum
    }

    costdatePiker.date = viewModel.costDate
  }

  @objc func saveAction(param: UIButton) {
    viewModel?.saveCostModel(
      costDate: costdatePiker.date, costName: costNameTextfield.text, costSum: costSumTextfield.text
    )
    navigationController?.popToRootViewController(animated: true)
  }

  @objc func cancelAction(param: UIButton) {
    navigationController?.popToRootViewController(animated: true)
  }
}

// MARK: - Constraints
extension CostDetailsListViewController {
  func setConstraints() {
    let buttonStackView = UIStackView(
      arrangedSubviews: [saveButton, cancelButton],
      axis: .horizontal,
      spacing: 20,
      distribution: .fillEqually)

    let dateStackView = UIStackView(
      arrangedSubviews: [costDateLabel, costdatePiker],
      axis: .horizontal,
      spacing: 20,
      distribution: .fill)

    let costStackView = UIStackView(
      arrangedSubviews: [
        dateStackView,
        costNameLabel,
        costNameTextfield,
        costSumLabel,
        costSumTextfield,
        buttonStackView,
      ],
      axis: .vertical,
      spacing: 10,
      distribution: .fillEqually)
    view.addSubview(costStackView)

    NSLayoutConstraint.activate([
      costStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      costStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      costStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      costStackView.heightAnchor.constraint(equalToConstant: 270),
    ])
  }
}
