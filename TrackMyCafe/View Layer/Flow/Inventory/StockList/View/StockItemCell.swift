//
//  StockItemCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import TinyConstraints
import UIKit

class StockItemCell: UITableViewCell {

    // MARK: - Views

    private let containerView = UIView()

    private let nameLabel: AppLabel = {
        let label = AppLabel(style: .bodyMedium)
        label.textColor = UIColor.Main.text
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let unitLabel: AppLabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.Main.secondaryText
        return label
    }()

    private let quantityLabel: AppLabel = {
        let label = AppLabel(style: .bodyBoldValue)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        return label
    }()

    private let costLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .right
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.edgesToSuperview()

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, unitLabel])
        infoStack.axis = .vertical
        infoStack.spacing = UIConstants.smallSpacing

        let valueStack = UIStackView(arrangedSubviews: [quantityLabel, costLabel])
        valueStack.axis = .vertical
        valueStack.spacing = UIConstants.smallSpacing
        valueStack.alignment = .trailing
        valueStack.setContentHuggingPriority(.required, for: .horizontal)
        valueStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let rootStack = UIStackView(arrangedSubviews: [infoStack, valueStack])
        rootStack.axis = .horizontal
        rootStack.alignment = .top
        rootStack.distribution = .fill
        rootStack.spacing = UIConstants.standardSpacing

        containerView.addSubview(rootStack)
        rootStack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardSpacing,
                right: UIConstants.standardPadding
            )
        )

        infoStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        infoStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    // MARK: - Configuration

    func configure(with model: IngredientModel) {
        // 1. Name + Unit
        nameLabel.text = "\(model.name), \(model.unit.localizedName)"

        // 2. Quantity (was at top right)
        quantityLabel.text = String(format: "%.2f", model.stockQuantity)

        // 3. Average Price (was at bottom right) -> now below Name
        unitLabel.text = String(
            format: R.string.global.inventoryAvgPrice(model.averageCost), model.averageCost)
        unitLabel.textColor = UIColor.Main.secondaryText

        // 4. Total Value (new) -> now at bottom right
        let totalValue = model.stockQuantity * model.averageCost
        costLabel.text = String(format: R.string.global.inventorySumValue(totalValue), totalValue)
        costLabel.textColor = UIColor.Main.secondaryText

        // Highlight low stock (hardcoded threshold 5.0 for now, ideally from settings)
        if model.stockQuantity < 5.0 {
            quantityLabel.textColor = .systemRed
        } else {
            quantityLabel.textColor = UIColor.Main.text
        }
    }
}
