//
//  PurchaseTableViewCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import UIKit
import TinyConstraints

class PurchaseTableViewCell: UITableViewCell {

    // MARK: - UI Elements
    private let nameLabel: AppLabel = {
        let label = AppLabel(style: .bodyMedium)
        label.textColor = UIColor.Main.text
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let detailsLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textColor = UIColor.Main.text.alpha(0.75)
        label.textAlignment = .right
        return label
    }()

    private let totalLabel: AppLabel = {
        let label = AppLabel(style: .bodyBoldValue)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        return label
    }()

    private let containerView: UIView = {
        UIView()
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let leftStack = UIStackView(arrangedSubviews: [nameLabel])
        leftStack.axis = .vertical
        leftStack.spacing = UIConstants.smallSpacing

        let rightStack = UIStackView(arrangedSubviews: [totalLabel, detailsLabel])
        rightStack.axis = .vertical
        rightStack.spacing = UIConstants.smallSpacing
        rightStack.alignment = .trailing

        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leftStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rootStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        rootStack.axis = .horizontal
        rootStack.alignment = .top
        rootStack.distribution = .fill
        rootStack.spacing = UIConstants.standardSpacing

        contentView.addSubview(containerView)
        containerView.addSubview(rootStack)

        containerView.edgesToSuperview()
        rootStack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardSpacing,
                right: UIConstants.standardPadding
            )
        )
    }

    // MARK: - Configuration
    func configure(with viewModel: PurchaseListItemViewModelType) {
        nameLabel.text = viewModel.name
        detailsLabel.text = "\(viewModel.quantity) x \(viewModel.price)"
        totalLabel.text = viewModel.total
    }
}
