//
//  ProductPriceTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.11.2021.
//

import UIKit

class ProductPriceTableViewCell: UITableViewCell {

  let backgroundViewCell: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.TableView.cellBackground
    view.layer.cornerRadius = 10
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }()

  let productLabel: UILabel = {
    let label = UILabel()
    label.text = "Esspresso"
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.TableView.cellLabel
    label.applyDynamic(Typography.body)

    return label
  }()

  let quantityLabel: UILabel = {
    let label = UILabel()
    label.text = "0"
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.TableView.cellLabel
    label.applyDynamic(Typography.body)

    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    self.backgroundColor = UIColor.Main.background

    setConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(productPrice: ProductsPriceModel, indexPath: IndexPath) {
    productLabel.text = productPrice.name
    quantityLabel.text = String(productPrice.price)

    selectionStyle = .none
  }

  func setConstraints() {

    self.addSubview(backgroundViewCell)
    NSLayoutConstraint.activate([
      backgroundViewCell.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
      backgroundViewCell.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
      backgroundViewCell.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
      backgroundViewCell.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1),
    ])

    self.addSubview(productLabel)
    NSLayoutConstraint.activate([
      productLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      productLabel.leadingAnchor.constraint(
        equalTo: backgroundViewCell.leadingAnchor, constant: 15),
    ])

    self.addSubview(quantityLabel)
    NSLayoutConstraint.activate([
      quantityLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      quantityLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
    ])

  }
}
