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
        // Using TinyConstraints syntax if available, otherwise manual
        // Assuming TinyConstraints is imported in this file? NO.
        // I need to import TinyConstraints or use NSLayoutConstraint.
        // The original file uses UIKit only.
        // Let's use NSLayoutConstraint to be safe and consistent with the file.
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        productLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        productStepper.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        
        containerView.addSubview(productLabel)
        containerView.addSubview(quantityLabel)
        containerView.addSubview(productStepper)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Name at the top
            productLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            productLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            productLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // Stepper at the bottom
            productStepper.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            productStepper.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Quantity in the middle
            quantityLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            quantityLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }
}
