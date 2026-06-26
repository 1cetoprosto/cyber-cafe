//
//  IngredientTableViewCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import TinyConstraints
import UIKit

final class IngredientTableViewCell: BaseListTableViewCell {

    static let identifier = "IngredientTableViewCell"

    // MARK: - UI Elements
    private let nameLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 2
        return label
    }()

    private let stockLabel: AppLabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.Main.secondaryText
        return label
    }()

    private let costLabel: AppLabel = {
        let label = AppLabel(style: .bodyValue)
        label.textColor = UIColor.TableView.cellLabel
        label.textAlignment = .right
        return label
    }()

    private let unitLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textColor = UIColor.Main.secondaryText
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

        contentView.addSubview(nameLabel)
        contentView.addSubview(stockLabel)
        contentView.addSubview(costLabel)
        contentView.addSubview(unitLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        // Left Column
        nameLabel.topToSuperview(offset: 10)
        nameLabel.leadingToSuperview(offset: 16)
        nameLabel.trailingToLeading(of: costLabel, offset: -10, relation: .equalOrLess)

        stockLabel.topToBottom(of: nameLabel, offset: 4)
        stockLabel.leadingToSuperview(offset: 16)
        stockLabel.bottomToSuperview(offset: -10)
        stockLabel.trailingToLeading(of: unitLabel, offset: -10, relation: .equalOrLess)

        // Right Column
        costLabel.topToSuperview(offset: 10)
        costLabel.trailingToSuperview(offset: 16)

        unitLabel.topToBottom(of: costLabel, offset: 4)
        unitLabel.trailingToSuperview(offset: 16)
        unitLabel.bottomToSuperview(offset: -10)
    }

    // MARK: - Configuration
    func configure(with ingredient: IngredientModel) {
        nameLabel.text = ingredient.name

        // Stock (Left Bottom, Gray): "35.0 l"
        stockLabel.text = "\(ingredient.stockQuantity) \(ingredient.unit.localizedName)"

        // Total Stock Value (Right Top, Bold): Stock * AvgCost
        let totalValue = ingredient.stockQuantity * ingredient.averageCost
        costLabel.text = String(format: "%.2f", totalValue)

        // Average Cost (Right Bottom): "12.50 per l"
        let avgCost = String(format: "%.2f", ingredient.averageCost)
        unitLabel.text = "\(avgCost) \(R.string.global.per()) \(ingredient.unit.localizedName)"
    }
}
