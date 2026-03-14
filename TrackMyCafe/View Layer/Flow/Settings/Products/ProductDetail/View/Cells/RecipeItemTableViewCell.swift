//
//  RecipeItemTableViewCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 09.11.2025.
//

import UIKit

class RecipeItemTableViewCell: UITableViewCell {

    // MARK: - UI Elements
    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = UIConstants.largeCornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let nameLabel: AppLabel = {
        let label = AppLabel(style: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    let quantityLabel: AppLabel = {
        let label = AppLabel(style: .bodyValue)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.textAlignment = .right
        return label
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear  // Transparent to show parent background
        self.selectionStyle = .none
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    func configure(item: RecipeItemModel) {
        nameLabel.text = item.ingredientName
        quantityLabel.text = "\(item.quantity.quantityFormat) \(item.unit.localizedName)"
    }

    // MARK: - Constraints
    private func setupConstraints() {
        contentView.addSubview(backgroundViewCell)
        let rowStackView = UIStackView(arrangedSubviews: [nameLabel, quantityLabel])
        rowStackView.axis = .horizontal
        rowStackView.alignment = .center
        rowStackView.distribution = .fill
        rowStackView.spacing = UIConstants.standardSpacing
        rowStackView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        quantityLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        quantityLabel.setContentHuggingPriority(.required, for: .horizontal)

        backgroundViewCell.addSubview(rowStackView)

        NSLayoutConstraint.activate([
            backgroundViewCell.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UIConstants.smallSpacing),
            backgroundViewCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundViewCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundViewCell.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UIConstants.smallSpacing),
        ])

        NSLayoutConstraint.activate([
            rowStackView.topAnchor.constraint(equalTo: backgroundViewCell.topAnchor, constant: UIConstants.mediumSpacing),
            rowStackView.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: UIConstants.standardPadding),
            rowStackView.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -UIConstants.standardPadding),
            rowStackView.bottomAnchor.constraint(equalTo: backgroundViewCell.bottomAnchor, constant: -UIConstants.mediumSpacing),
        ])
    }
}
