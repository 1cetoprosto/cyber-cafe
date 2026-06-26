//
//  PurchaseTableViewCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import TinyConstraints
import UIKit

final class PurchaseTableViewCell: BaseListTableViewCell {

    // MARK: - UI Elements
    private let nameLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 2
        return label
    }()

    private let detailsLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .right
        return label
    }()

    private let totalLabel: AppLabel = {
        let label = AppLabel(style: .bodyValue)
        label.textColor = UIColor.TableView.cellLabel
        label.textAlignment = .right
        return label
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Setup
    private func setupView() {
        accessoryType = .disclosureIndicator

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
        rootStack.alignment = .center
        rootStack.distribution = .fill
        rootStack.spacing = UIConstants.standardSpacing

        contentView.addSubview(rootStack)
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
