//
//  ScheduleTableViewCell.swift
//  
//
//  Created by Леонід Квіт on 05.11.2021.
//

import UIKit

class SalesTableViewCell: UITableViewCell {

    static let identifier = "idSalesCell"
    
    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    lazy var goodsName = createSalesLabel(text: "05.09.21", font: .avenirNext20(), aligment: .left)
    lazy var salesSum = createSalesLabel(text: "640", font: .avenirNext14(), aligment: .right)
    lazy var salesLabel = createSalesLabel(text: "Plan:", font: .avenirNext14(), aligment: .left)
    lazy var cashSum = createSalesLabel(text: "230", font: .avenirNext20(), aligment: .right)
    //lazy var cashLabel = createSalesLabel(text: "Donat:", font: .avenirNext14(), aligment: .right)

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

    weak var viewModel: SaleListItemViewModelType? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            goodsName.text = viewModel.goodsName
            salesSum.text = viewModel.salesSum
            cashSum.text = viewModel.cashSum
        }
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
            goodsName.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 16),
            //goodsName.widthAnchor.constraint(equalToConstant: 200),
            goodsName.heightAnchor.constraint(equalToConstant: 50)
        ])

//        let cashStackView = UIStackView(arrangedSubviews: [cashLabel, cashSum],
//                                        axis: .horizontal,
//                                        spacing: 5,
//                                        distribution: .fillEqually)

        self.addSubview(cashSum) // cashStackView
        NSLayoutConstraint.activate([
            cashSum.topAnchor.constraint(equalTo: backgroundViewCell.topAnchor, constant: 15),
//            cashSum.leadingAnchor.constraint(equalTo: goodsName.trailingAnchor, constant: 5),
//            cashSum.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
//            cashSum.heightAnchor.constraint(equalToConstant: 25)
//            cashSum.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            cashSum.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -30),
            cashSum.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        let salesStackView = UIStackView(arrangedSubviews: [salesLabel, salesSum],
                                         axis: .horizontal,
                                         spacing: 5,
                                         distribution: .fillEqually)

        self.addSubview(salesStackView)
        NSLayoutConstraint.activate([
            salesStackView.bottomAnchor.constraint(equalTo: backgroundViewCell.bottomAnchor, constant: 0),
//            salesStackView.leadingAnchor.constraint(equalTo: goodsName.trailingAnchor, constant: 5),
            salesStackView.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -30),
            salesStackView.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
}
