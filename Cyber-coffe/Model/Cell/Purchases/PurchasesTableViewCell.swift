//
//  PurchasesTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit

class PurchasesTableViewCell: UITableViewCell {
    
    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    lazy var purchaseDate = createSalesLabel(text: "05.09.21", font: .avenirNext14(), aligment: .left)
    lazy var purchaseName = createSalesLabel(text: "Milk", font: .avenirNextDemiBold20(), aligment: .left)
    lazy var purchaseSum = createSalesLabel(text: "640", font: .avenirNextDemiBold20(), aligment: .left)
    lazy var purchaseLabel = createSalesLabel(text: "Sum:", font: .avenirNext14(), aligment: .right)
    
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
    
    func setConstraints() {
        
        self.addSubview(backgroundViewCell)
        NSLayoutConstraint.activate([
            backgroundViewCell.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            backgroundViewCell.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            backgroundViewCell.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            backgroundViewCell.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1)
        ])
        
        let purchaseDateNameStackView = UIStackView(arrangedSubviews: [purchaseDate, purchaseName], axis: .vertical, spacing: 5, distribution: .fillEqually)
        
        self.addSubview(purchaseDateNameStackView)
        NSLayoutConstraint.activate([
            purchaseDateNameStackView.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            purchaseDateNameStackView.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 5),
            purchaseDateNameStackView.widthAnchor.constraint(equalToConstant: 200),
            purchaseDateNameStackView.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        let purchaseSumStackView = UIStackView(arrangedSubviews: [purchaseLabel, purchaseSum], axis: .horizontal, spacing: 5, distribution: .fillEqually)

        self.addSubview(purchaseSumStackView)
        NSLayoutConstraint.activate([
            purchaseSumStackView.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            purchaseSumStackView.leadingAnchor.constraint(equalTo: purchaseDateNameStackView.trailingAnchor, constant: 5),
            purchaseSumStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            purchaseSumStackView.heightAnchor.constraint(equalToConstant: 25),
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
        //label.backgroundColor = .systemRed
        
        return label
    }
}
