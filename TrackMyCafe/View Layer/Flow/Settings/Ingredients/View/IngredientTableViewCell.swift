//
//  IngredientTableViewCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import TinyConstraints
import UIKit

class IngredientTableViewCell: UITableViewCell {

    static let identifier = "IngredientTableViewCell"

    // MARK: - UI Elements
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.Main.text
        return label
    }()

    private let stockLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.gray
        return label
    }()

    private let costLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        return label
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        return label
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
