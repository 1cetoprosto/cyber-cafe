//
//  PurchasesTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit

class PurchasesTableViewCell: UITableViewCell {

    static let identifier = "idPurchasesCell"
    
    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    lazy var purchaseName = createSalesLabel(text: "Milk", font: .avenirNext20(), aligment: .left)
    lazy var purchaseSum = createSalesLabel(text: "640", font: .avenirNext20(), aligment: .right) 

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.cornerRadius = 10
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        backgroundColor = UIColor.Main.background

        setConstraints()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var viewModel: PurchaseListItemViewModelType? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            purchaseDate.text = viewModel.purchaseDate
            purchaseName.text = viewModel.purchaseName
            purchaseSum.text = viewModel.purchaseSum
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
        
        self.addSubview(purchaseName)
        NSLayoutConstraint.activate([
            purchaseName.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            purchaseName.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 16),
            purchaseName.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        self.addSubview(purchaseSum)
        NSLayoutConstraint.activate([
            purchaseSum.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            purchaseSum.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -30),
            purchaseSum.heightAnchor.constraint(equalToConstant: 25)
        ])
    }

    func createSalesLabel(text: String, font: UIFont?, aligment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = UIColor.TableView.cellLabel
        label.textAlignment = aligment
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }
}
