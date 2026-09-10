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

    private let lowStockBadgeImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(
            systemName: "exclamationmark.triangle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        iv.isHidden = true
        return iv
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
        accessoryType = .none

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, unitLabel])
        infoStack.axis = .vertical
        infoStack.spacing = UIConstants.smallSpacing

        let quantityRow = UIStackView(arrangedSubviews: [lowStockBadgeImageView, quantityLabel])
        quantityRow.axis = .horizontal
        quantityRow.alignment = .center
        quantityRow.spacing = 6

        let valueStack = UIStackView(arrangedSubviews: [quantityRow, costLabel])
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

        let threshold = model.minStockThreshold ?? 5.0
        let isLowStock = model.stockQuantity < threshold
        lowStockBadgeImageView.isHidden = !isLowStock
        if isLowStock {
            quantityLabel.textColor = .systemRed
            let thresholdText = String(format: "%.2f", threshold)
            accessibilityValue =
                "\(model.name). Stock: \(model.stockQuantity) \(model.unit.localizedName). Low stock (below threshold \(thresholdText)). Total value \(totalValue)."
        } else {
            quantityLabel.textColor = UIColor.TableView.cellLabel
            accessibilityValue =
                "\(model.name). Stock: \(model.stockQuantity) \(model.unit.localizedName). Total value \(totalValue)."
        }
    }
}
