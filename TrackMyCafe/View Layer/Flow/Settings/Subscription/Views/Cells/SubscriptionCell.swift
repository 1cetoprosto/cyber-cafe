//
//  SubscriptionCell.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import UIKit
import StoreKit

class SubscriptionCell: UITableViewCell {
    static let identifier = CellIdentifiers.subscriptionCell
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        
        return view
    }()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 4
        view.size(50)
        view.image = R.image.appLogo()
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        return label
    }()
    
    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        backgroundColor = UIColor.Main.background 
        contentView.backgroundColor = UIColor.Main.background
        contentView.addSubview(containerView)
        containerView.horizontalToSuperview(insets: .horizontal(15))
        containerView.verticalToSuperview(insets: .vertical(8))
        
        let stack1 = UIStackView.HStack([nameLabel, priceLabel], spacing: 4)
        let stack2 = UIStackView.VStack([stack1, infoLabel], spacing: 4)
        let stack3 = UIStackView.HStack([iconView.wrapVTop(), stack2], spacing: 8)
        
        containerView.addSubview(stack3)
        stack3.edgesToSuperview(insets: .init(top: 8, left: 8, bottom: 8, right: 15))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        contentView.frame = bounds.inset(by: margins)
    }
    
    func setup(_ product: SKProduct) {
        guard let type = SubscriptionType(rawValue: product.productIdentifier) else { return }
        nameLabel.text = type.name
        infoLabel.text = type.info
        
        let formatter = NumberFormatter()
        formatter.locale = product.priceLocale
        formatter.numberStyle = .currency
        let price = formatter.string(from: product.price) ?? product.localizedPrice ?? "\(product.price)"
        priceLabel.text = "\(price) / \(R.string.global.month())"
    }
}

