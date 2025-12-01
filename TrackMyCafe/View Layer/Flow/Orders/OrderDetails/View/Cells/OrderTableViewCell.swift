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
        label.text = "Esspresso"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)

        return label
    }()

    let quantityLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
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
            productStepper.value = viewModel.productStepperValue //stepperValue
            productStepper.tag = viewModel.productStepperTag //indexPath.row
        }
    }
    
    func setConstraints() {

        self.addSubview(backgroundViewCell)
        NSLayoutConstraint.activate([
            backgroundViewCell.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            backgroundViewCell.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            backgroundViewCell.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            backgroundViewCell.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1)
        ])

        self.addSubview(productLabel)
        NSLayoutConstraint.activate([
            productLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            productLabel.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 15)
        ])

        self.contentView.addSubview(productStepper)
        NSLayoutConstraint.activate([
            productStepper.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            productStepper.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -20)
        ])

        self.contentView.addSubview(quantityLabel)
        NSLayoutConstraint.activate([
            quantityLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            quantityLabel.trailingAnchor.constraint(equalTo: productStepper.leadingAnchor, constant: -20)
        ])
    }
}
