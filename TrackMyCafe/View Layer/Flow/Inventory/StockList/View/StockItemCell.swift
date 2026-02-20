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

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.Main.text
        return label
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.Main.secondaryText
        return label
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        return label
    }()

    private let costLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
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
        containerView.edgesToSuperview(insets: .uniform(8))

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, unitLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4

        let valueStack = UIStackView(arrangedSubviews: [quantityLabel, costLabel])
        valueStack.axis = .vertical
        valueStack.spacing = 4
        valueStack.alignment = .trailing

        containerView.addSubview(infoStack)
        containerView.addSubview(valueStack)

        infoStack.leadingToSuperview()
        infoStack.centerYToSuperview()

        valueStack.trailingToSuperview()
        valueStack.centerYToSuperview()

        infoStack.trailingToLeading(of: valueStack, offset: -8, relation: .equalOrLess)
        valueStack.width(min: 80)  // Ensure enough space for values
    }

    // MARK: - Configuration

    func configure(with model: IngredientModel) {
        // 1. Name + Unit
        nameLabel.text = "\(model.name), \(model.unit.localizedName)"

        // 2. Quantity (was at top right)
        quantityLabel.text = String(format: "%.2f", model.stockQuantity)

        // 3. Average Price (was at bottom right) -> now below Name
        unitLabel.text = String(format: "Avg: %.2f UAH", model.averageCost)

        // 4. Total Value (new) -> now at bottom right
        let totalValue = model.stockQuantity * model.averageCost
        costLabel.text = String(format: "Sum: %.2f UAH", totalValue)

        // Highlight low stock (hardcoded threshold 5.0 for now, ideally from settings)
        if model.stockQuantity < 5.0 {
            quantityLabel.textColor = .systemRed
        } else {
            quantityLabel.textColor = UIColor.Main.text
        }
    }
}
