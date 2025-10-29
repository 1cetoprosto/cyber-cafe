//
//  ScheduleTableViewCell.swift
//
//
//  Created by Леонід Квіт on 05.11.2021.
//

import UIKit

class OrdersTableViewCell: UITableViewCell {

  static let identifier = CellIdentifiers.ordersCell

  let backgroundViewCell: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.TableView.cellBackground
    view.layer.cornerRadius = UIConstants.largeCornerRadius
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }()

  lazy var productsName = createOrdersLabel(
    text: "05.09.21", font: .avenirNext20(), aligment: .left)
  lazy var ordersSum = createOrdersLabel(text: "640", font: .avenirNext14(), aligment: .right)
  lazy var ordersLabel = createOrdersLabel(
    text: R.string.global.plan(), font: .avenirNext14(), aligment: .left)
  lazy var cashSum = createOrdersLabel(text: "230", font: .avenirNext20(), aligment: .right)

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    layer.cornerRadius = UIConstants.largeCornerRadius
    selectionStyle = .none
    accessoryType = .disclosureIndicator
    backgroundColor = UIColor.Main.background

    setConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  weak var viewModel: OrderListItemViewModelType? {
    willSet(viewModel) {
      guard let viewModel = viewModel else { return }
      productsName.text = viewModel.productsName
      ordersSum.text = viewModel.ordersSum
      cashSum.text = viewModel.cashSum
    }
  }

  func createOrdersLabel(text: String, font: UIFont?, aligment: NSTextAlignment) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = font
    label.textColor = UIColor.TableView.cellLabel
    label.textAlignment = aligment
    label.adjustsFontSizeToFitWidth = true
    label.translatesAutoresizingMaskIntoConstraints = false

    return label
  }

  func setConstraints() {

    self.addSubview(backgroundViewCell)
    NSLayoutConstraint.activate([
      backgroundViewCell.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
      backgroundViewCell.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
      backgroundViewCell.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
      backgroundViewCell.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1),
    ])

    self.addSubview(productsName)
    NSLayoutConstraint.activate([
      productsName.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
      productsName.leadingAnchor.constraint(
        equalTo: backgroundViewCell.leadingAnchor, constant: 16),
      //productsName.widthAnchor.constraint(equalToConstant: 200),
      productsName.heightAnchor.constraint(equalToConstant: 50),
    ])

    //        let cashStackView = UIStackView(arrangedSubviews: [cashLabel, cashSum],
    //                                        axis: .horizontal,
    //                                        spacing: 5,
    //                                        distribution: .fillEqually)

    self.addSubview(cashSum)  // cashStackView
    NSLayoutConstraint.activate([
      cashSum.topAnchor.constraint(equalTo: backgroundViewCell.topAnchor, constant: 15),
      //            cashSum.leadingAnchor.constraint(equalTo: productsName.trailingAnchor, constant: 5),
      //            cashSum.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
      //            cashSum.heightAnchor.constraint(equalToConstant: 25)
      //            cashSum.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
      cashSum.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -30),
      cashSum.heightAnchor.constraint(equalToConstant: 25),
    ])

    let ordersStackView = UIStackView(
      arrangedSubviews: [ordersLabel, ordersSum],
      axis: .horizontal,
      spacing: 5,
      distribution: .fillEqually)

    self.addSubview(ordersStackView)
    NSLayoutConstraint.activate([
      ordersStackView.bottomAnchor.constraint(
        equalTo: backgroundViewCell.bottomAnchor, constant: 0),
      //            ordersStackView.leadingAnchor.constraint(equalTo: productsName.trailingAnchor, constant: 5),
      ordersStackView.trailingAnchor.constraint(
        equalTo: backgroundViewCell.trailingAnchor, constant: -30),
      ordersStackView.heightAnchor.constraint(equalToConstant: 25),
    ])
  }
}
