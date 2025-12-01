//
//  SettingsDataTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.12.2021.
//

import UIKit

class SettingsDataTableViewCell: BaseSettingsCell {

  let dataLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 1
    label.textAlignment = .right
    label.textColor = UIColor.TableView.cellLabel
    label.applyDynamic(Typography.footnote)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    contentView.addSubview(dataLabel)

    NSLayoutConstraint.activate([
      dataLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      dataLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -35),
      dataLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    iconImageView.image = nil
    label.text = nil
    iconContainer.backgroundColor = nil
    dataLabel.text = nil
  }

  func configure(with model: SettingsDataOption) {
    label.text = model.title
    iconImageView.image = model.icon
    iconContainer.backgroundColor = model.iconBackgroundColor
    dataLabel.text = model.data
  }
}
