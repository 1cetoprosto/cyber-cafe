//
//  SettingsStaticTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 24.11.2021.
//

import UIKit

final class SettingsStaticTableViewCell: BaseSettingsCell {

    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "info.circle")
        button.setImage(image, for: .normal)
        button.tintColor = UIColor.Main.secondaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return button
    }()

    private var infoHandler: (() -> Void)?
    private var dynamicTrailingConstraint: NSLayoutConstraint?

    func configure(with option: SettingsStaticOption) {
        label.text = option.title
        iconImageView.image = option.icon
        iconContainer.backgroundColor = option.iconBackgroundColor

        infoHandler = option.infoHandler
        infoButton.isHidden = option.infoHandler == nil

        // Deactivate base trailing constraint and apply the dynamic one
        labelTrailingConstraint?.isActive = false
        dynamicTrailingConstraint?.isActive = false

        if option.infoHandler != nil {
            dynamicTrailingConstraint = label.trailingAnchor.constraint(
                equalTo: infoButton.leadingAnchor, constant: -8)
        } else {
            dynamicTrailingConstraint = label.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -15)
        }
        dynamicTrailingConstraint?.isActive = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupInfoButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupInfoButton()
    }

    private func setupInfoButton() {
        contentView.addSubview(infoButton)

        NSLayoutConstraint.activate([
            infoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -8),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @objc private func infoButtonTapped() {
        infoHandler?()
    }
}
