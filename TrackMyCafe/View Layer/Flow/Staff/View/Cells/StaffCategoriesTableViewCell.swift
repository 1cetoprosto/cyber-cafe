//
//  StaffCategoriesTableViewCell.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 06.07.2024.
//

import UIKit

class StaffCategoriesTableViewCell: UITableViewCell {

  let backgroundViewCell: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.TableView.cellBackground
    view.layer.cornerRadius = 10
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }()

  let typeLabel: UILabel = {
    let label = UILabel()
    label.text = ""
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.TableView.cellLabel

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

  func configure(type: TypeModel, indexPath: IndexPath) {
    typeLabel.text = type.name
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

    self.addSubview(typeLabel)
    NSLayoutConstraint.activate([
      typeLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      typeLabel.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 15),
    ])

  }
}
