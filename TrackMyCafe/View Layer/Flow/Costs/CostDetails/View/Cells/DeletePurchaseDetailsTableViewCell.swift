//
//  CostDetailsTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit

class CostDetailsTableViewCell: UITableViewCell {

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

    let cellNameArray = ["Esspresso",
                         "Amerecano",
                         "Amerecano with milk",
                         "Capuchino",
                         "Ayrish",
                         "Latte",
                         "Cacao",
                         "Hot chocolad"]

    let cellQuantityArray = ["0", "0", "0", "0", "0", "0", "0", "0"]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.Main.background
        productStepper.addTarget(self, action: #selector(stepperAction), for: .valueChanged)
        setConstraints()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(indexPath: IndexPath) {
        productLabel.text = cellNameArray[indexPath.row]
        quantityLabel.text = cellQuantityArray[indexPath.row]
        selectionStyle = .none
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

    @objc func stepperAction(_ sender: UIStepper) {
        quantityLabel.text = String(Int(sender.value))
    }
}
