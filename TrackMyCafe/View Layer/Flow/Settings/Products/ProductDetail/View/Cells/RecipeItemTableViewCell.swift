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
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)
        return label
    }()
    
    let quantityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.textAlignment = .right
        label.applyDynamic(Typography.body)
        return label
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear // Transparent to show parent background
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
}
    
    // MARK: - Constraints
    private func setupConstraints() {
        contentView.addSubview(backgroundViewCell)
        backgroundViewCell.addSubview(nameLabel)
        backgroundViewCell.addSubview(quantityLabel)
        
        // Background View (Card)
        // Matching ProductPriceTableViewCell: top 0, bottom -1 (for small gap), leading/trailing 0
        // But since we want "card" look, maybe we want some vertical spacing if the screenshot implies it.
        // ProductPriceTableViewCell uses:
        // top: 0, leading: 0, trailing: 0, bottom: -1
        // Let's stick to that to be "the same".
        
        NSLayoutConstraint.activate([
            backgroundViewCell.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundViewCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundViewCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundViewCell.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1)
        ])
        
        // Name Label
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 15)
        ])
        
        // Quantity Label
        NSLayoutConstraint.activate([
            quantityLabel.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            quantityLabel.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -15),
            quantityLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 10)
        ])
    }
}
