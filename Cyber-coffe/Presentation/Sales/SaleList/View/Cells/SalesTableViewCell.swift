//
//  ScheduleTableViewCell.swift
//  
//
//  Created by Леонід Квіт on 05.11.2021.
//

import UIKit

class SalesTableViewCell: UITableViewCell {

    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    lazy var goodsName = createSalesLabel(text: "05.09.21", font: .avenirNext20(), aligment: .left)
    lazy var salesSum = createSalesLabel(text: "640", font: .avenirNextDemiBold20(), aligment: .left)
    lazy var salesLabel = createSalesLabel(text: "Sale:", font: .avenirNext14(), aligment: .right)
    lazy var cashSum = createSalesLabel(text: "230", font: .avenirNextDemiBold20(), aligment: .left)
    lazy var cashLabel = createSalesLabel(text: "Cash:", font: .avenirNext14(), aligment: .right)

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

    func configure(sale: SalesModel) {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        goodsName.text = dateFormatter.string(from: sale.salesDate)

        salesSum.text = String(Int(sale.salesSum))
        cashSum.text = String(Int(sale.salesCash))

        selectionStyle = .none
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

    func setConstraints() {

        self.addSubview(backgroundViewCell)
        NSLayoutConstraint.activate([
            backgroundViewCell.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            backgroundViewCell.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            backgroundViewCell.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            backgroundViewCell.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1)
        ])

        self.addSubview(goodsName)
        NSLayoutConstraint.activate([
            goodsName.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            goodsName.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 20),
            goodsName.widthAnchor.constraint(equalToConstant: 200),
            goodsName.heightAnchor.constraint(equalToConstant: 50)
        ])

        let salesStackView = UIStackView(arrangedSubviews: [salesLabel, salesSum],
                                         axis: .horizontal,
                                         spacing: 5,
                                         distribution: .fillEqually)

        self.addSubview(salesStackView)
        NSLayoutConstraint.activate([
            salesStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            salesStackView.leadingAnchor.constraint(equalTo: goodsName.trailingAnchor, constant: 5),
            salesStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            salesStackView.heightAnchor.constraint(equalToConstant: 25)
        ])

        let cashStackView = UIStackView(arrangedSubviews: [cashLabel, cashSum],
                                        axis: .horizontal,
                                        spacing: 5,
                                        distribution: .fillEqually)

        self.addSubview(cashStackView)
        NSLayoutConstraint.activate([
            cashStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            cashStackView.leadingAnchor.constraint(equalTo: goodsName.trailingAnchor, constant: 5),
            cashStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            cashStackView.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
}
