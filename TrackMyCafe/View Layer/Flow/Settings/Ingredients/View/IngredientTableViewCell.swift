//
//  IngredientTableViewCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import UIKit

class IngredientTableViewCell: UITableViewCell {
    
    static let identifier = "IngredientTableViewCell"
    
    // MARK: - UI Elements
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.Main.text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stockLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let costLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
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
        NSLayoutConstraint.activate([
            // Left Column
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: costLabel.leadingAnchor, constant: -10),
            
            stockLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            stockLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stockLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            stockLabel.trailingAnchor.constraint(lessThanOrEqualTo: unitLabel.leadingAnchor, constant: -10),
            
            // Right Column
            costLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            costLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            unitLabel.topAnchor.constraint(equalTo: costLabel.bottomAnchor, constant: 4),
            unitLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unitLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    // MARK: - Configuration
    func configure(with ingredient: IngredientModel) {
        nameLabel.text = ingredient.name
        
        // Stock: "35.0 l"
        stockLabel.text = "\(ingredient.stockQuantity) \(ingredient.unit.localizedName)"
        
        // Cost: "12.50"
        costLabel.text = String(format: "%.2f", ingredient.averageCost)
        
        // Unit label: "per l" (e.g. "за л")
        unitLabel.text = "\(R.string.global.per()) \(ingredient.unit.localizedName)"
    }
}
