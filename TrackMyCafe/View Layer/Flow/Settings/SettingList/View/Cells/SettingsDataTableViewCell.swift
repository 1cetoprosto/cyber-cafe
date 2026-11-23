//
//  SettingsDataTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.12.2021.
//

import UIKit

class SettingsDataTableViewCell: BaseSettingsCell {

    let dataLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textAlignment = .right
        label.textColor = UIColor.TableView.cellLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var labelTrailingToData: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(dataLabel)

        labelTrailingConstraint?.isActive = false
        labelTrailingToData = label.trailingAnchor.constraint(
            lessThanOrEqualTo: dataLabel.leadingAnchor, constant: -10)

        NSLayoutConstraint.activate([
            dataLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dataLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -35),
            dataLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150),
        ])
        labelTrailingToData?.isActive = true
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
