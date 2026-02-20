//
//  PurchaseTableViewCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import UIKit
import TinyConstraints

class PurchaseTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.Main.text
        return label
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        return label
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
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
        contentView.addSubview(detailsLabel)
        contentView.addSubview(totalLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        nameLabel.centerYToSuperview()
        nameLabel.leadingToSuperview(offset: 16)
        nameLabel.trailing(to: detailsLabel, offset: -10, relation: .equalOrLess)
        
        totalLabel.topToSuperview(offset: 10)
        totalLabel.trailingToSuperview(offset: 16)
        
        detailsLabel.topToBottom(of: totalLabel, offset: 4)
        detailsLabel.trailingToSuperview(offset: 16)
        detailsLabel.bottomToSuperview(offset: -10)
    }
    
    // MARK: - Configuration
    func configure(with viewModel: PurchaseListItemViewModelType) {
        nameLabel.text = viewModel.name
        detailsLabel.text = "\(viewModel.quantity) x \(viewModel.price)"
        totalLabel.text = viewModel.total
    }
}
