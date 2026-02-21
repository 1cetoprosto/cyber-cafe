//
//  OrderCollectionViewCell.swift
//  Cyber-coffe
//
//  Created by Trae AI on 21.02.2026.
//

import TinyConstraints
import UIKit

class OrderCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 12
        // Optional: Add shadow for card effect
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    let productLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)
        return label
    }()
    
    let quantityLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)
        return label
    }()
    
    let productStepper: UIStepper = {
        let stepper = UIStepper()
        return stepper
    }()
    
    // MARK: - ViewModel
    weak var viewModel: ProductListItemViewModelType? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            productLabel.text = viewModel.productLabel
            quantityLabel.text = viewModel.quantityLabel
            productStepper.value = viewModel.productStepperValue
            productStepper.tag = viewModel.productStepperTag
        }
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.edgesToSuperview(insets: .uniform(4))
        
        containerView.addSubview(productLabel)
        containerView.addSubview(quantityLabel)
        containerView.addSubview(productStepper)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Name at the top
        productLabel.topToSuperview(offset: 8)
        productLabel.leadingToSuperview(offset: 8)
        productLabel.trailingToSuperview(offset: 8)
        
        // Stepper at the bottom
        productStepper.bottomToSuperview(offset: -8)
        productStepper.centerXToSuperview()
        
        // Quantity in the middle
        quantityLabel.centerInSuperview()
        // Or between name and stepper
        // quantityLabel.topToBottom(of: productLabel, offset: 8)
        // quantityLabel.bottomToTop(of: productStepper, offset: -8)
    }
}
