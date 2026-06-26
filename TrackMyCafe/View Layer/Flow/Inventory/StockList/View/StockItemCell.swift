//
//  StockItemCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import TinyConstraints
import UIKit

final class StockItemCell: BaseListTableViewCell {

    // MARK: - Views

    private let nameLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 2
        return label
    }()

    private let unitLabel: AppLabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.Main.secondaryText
        return label
    }()

    private let quantityLabel: AppLabel = {
        let label = AppLabel(style: .bodyValue)
        label.textColor = UIColor.TableView.cellLabel
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
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Setup

    private func setupUI() {
        accessoryType = .disclosureIndicator

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

        contentView.addSubview(rootStack)
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
        nameLabel.text = "\(model.name), \(model.unit.localizedName)"

        quantityLabel.text = String(format: "%.2f", model.stockQuantity)

        unitLabel.text = String(
            format: R.string.global.inventoryAvgPrice(model.averageCost), model.averageCost)

        let totalValue = model.stockQuantity * model.averageCost
        costLabel.text = String(format: R.string.global.inventorySumValue(totalValue), totalValue)

        if model.stockQuantity < 5.0 {
            quantityLabel.textColor = .systemRed
        } else {
            quantityLabel.textColor = UIColor.TableView.cellLabel
        }
    }
}
