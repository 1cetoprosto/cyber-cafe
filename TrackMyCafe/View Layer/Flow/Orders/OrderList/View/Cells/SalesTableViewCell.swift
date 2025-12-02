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
    text: "05.09.21", font: Typography.body, aligment: .left)
  lazy var ordersSum = createOrdersLabel(text: "640", font: Typography.body, aligment: .right)

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
    }
  }

  func createOrdersLabel(text: String, font: UIFont, aligment: NSTextAlignment) -> UILabel {
    let label = UILabel()
    label.text = text
    label.applyDynamic(font)
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
    ])

    //        let cashStackView = UIStackView(arrangedSubviews: [cashLabel, cashSum],
    //                                        axis: .horizontal,
    //                                        spacing: 5,
    //                                        distribution: .fillEqually)

    self.addSubview(ordersSum)
    NSLayoutConstraint.activate([
      ordersSum.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
      ordersSum.trailingAnchor.constraint(
        equalTo: backgroundViewCell.trailingAnchor, constant: -16),
    ])

    NSLayoutConstraint.activate([
      productsName.trailingAnchor.constraint(
        lessThanOrEqualTo: ordersSum.leadingAnchor, constant: -12)
    ])
  }
}
