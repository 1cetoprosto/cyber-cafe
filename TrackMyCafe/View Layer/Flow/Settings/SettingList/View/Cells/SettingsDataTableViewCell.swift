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

    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.tintColor = UIColor.Main.secondaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return button
    }()

    private var infoHandler: (() -> Void)?
    private var labelTrailingToData: NSLayoutConstraint?
    private var labelTrailingToInfo: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(dataLabel)
        contentView.addSubview(infoButton)

        labelTrailingConstraint?.isActive = false

        labelTrailingToData = label.trailingAnchor.constraint(
            equalTo: dataLabel.leadingAnchor, constant: -10)
        labelTrailingToInfo = label.trailingAnchor.constraint(
            equalTo: infoButton.leadingAnchor, constant: -8)

        NSLayoutConstraint.activate([
            dataLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dataLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -35),
            dataLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150),

            infoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoButton.trailingAnchor.constraint(
                equalTo: dataLabel.leadingAnchor, constant: -8),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24),
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
        infoHandler = nil
        infoButton.isHidden = true
    }

    func configure(with model: SettingsDataOption) {
        label.text = model.title
        iconImageView.image = model.icon
        iconContainer.backgroundColor = model.iconBackgroundColor
        dataLabel.text = model.data
        infoHandler = model.infoHandler

        let showInfo = model.infoHandler != nil
        infoButton.isHidden = !showInfo
        labelTrailingToData?.isActive = !showInfo
        labelTrailingToInfo?.isActive = showInfo
    }

    @objc private func infoButtonTapped() {
        infoHandler?()
    }
}
