//
//  SaleTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit

class SaleTableViewCell: UITableViewCell {

    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    let goodLabel: UILabel = {
        let label = UILabel()
        label.text = "Esspresso"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel

        return label
    }()

    let quantityLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.TableView.cellLabel

        return label
    }()

    let goodStepper: UIStepper = {
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

    weak var viewModel: SaleGoodListItemViewModelType? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            goodLabel.text = viewModel.goodLabel
            quantityLabel.text = viewModel.quantityLabel
            goodStepper.value = viewModel.goodStepperValue //stepperValue
            goodStepper.tag = viewModel.goodStepperTag //indexPath.row
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

        self.addSubview(goodLabel)
        NSLayoutConstraint.activate([
            goodLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            goodLabel.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 15)
        ])

        self.contentView.addSubview(goodStepper)
        NSLayoutConstraint.activate([
            goodStepper.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            goodStepper.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -20)
        ])

        self.contentView.addSubview(quantityLabel)
        NSLayoutConstraint.activate([
            quantityLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            quantityLabel.trailingAnchor.constraint(equalTo: goodStepper.leadingAnchor, constant: -20)
        ])
    }
}
