//
//  OrderTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit

class OrderTableViewCell: UITableViewCell {

  let backgroundViewCell: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.TableView.cellBackground
    view.layer.cornerRadius = 10
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }()

  let productLabel: UILabel = {
    let label = UILabel()
    label.text = ""
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.TableView.cellLabel
    label.applyDynamic(Typography.body)

    return label
  }()

  let quantityLabel: UILabel = {
    let label = UILabel()
    label.text = ""
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor.TableView.cellLabel
    label.applyDynamic(Typography.body)

    return label
  }()

  let productStepper: UIStepper = {
    let stepper = UIStepper()
    stepper.translatesAutoresizingMaskIntoConstraints = false

    return stepper
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    self.backgroundColor = UIColor.Main.background
    setConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  weak var viewModel: ProductListItemViewModelType? {
    willSet(viewModel) {
      guard let viewModel = viewModel else { return }
      productLabel.text = viewModel.productLabel
      quantityLabel.text = viewModel.quantityLabel
      productStepper.value = viewModel.productStepperValue  //stepperValue
      productStepper.tag = viewModel.productStepperTag  //indexPath.row
    }
  }

  func setConstraints() {

    self.addSubview(backgroundViewCell)
    NSLayoutConstraint.activate([
      backgroundViewCell.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
      backgroundViewCell.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
      backgroundViewCell.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
      backgroundViewCell.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1),
    ])

    self.addSubview(productLabel)
    NSLayoutConstraint.activate([
      productLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      productLabel.leadingAnchor.constraint(
        equalTo: backgroundViewCell.leadingAnchor, constant: 15),
    ])

    self.contentView.addSubview(productStepper)
    NSLayoutConstraint.activate([
      productStepper.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      productStepper.trailingAnchor.constraint(
        equalTo: backgroundViewCell.trailingAnchor, constant: -20),
    ])

    self.contentView.addSubview(quantityLabel)
    NSLayoutConstraint.activate([
      quantityLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
      quantityLabel.trailingAnchor.constraint(equalTo: productStepper.leadingAnchor, constant: -20),
    ])
  }
}

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
