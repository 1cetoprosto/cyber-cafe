//
//  CostsTableViewCell.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit

class CostsTableViewCell: UITableViewCell {

    static let identifier = CellIdentifiers.costsCell
    
    let backgroundViewCell: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    lazy var costName = createOrdersLabel(text: "Milk", font: Typography.body, aligment: .left)
    lazy var costSum = createOrdersLabel(text: "640", font: Typography.body, aligment: .right) 

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        //layer.cornerRadius = 50
        //selectionStyle = .none
        accessoryType = .disclosureIndicator
        backgroundColor = UIColor.Main.background

        setConstraints()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var viewModel: CostListItemViewModelType? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            costName.text = viewModel.costName
            costSum.text = viewModel.costSum
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
        
        self.addSubview(costName)
        NSLayoutConstraint.activate([
            costName.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            costName.leadingAnchor.constraint(equalTo: backgroundViewCell.leadingAnchor, constant: 16),
            costName.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        self.addSubview(costSum)
        NSLayoutConstraint.activate([
            costSum.centerYAnchor.constraint(equalTo: backgroundViewCell.centerYAnchor),
            costSum.trailingAnchor.constraint(equalTo: backgroundViewCell.trailingAnchor, constant: -30),
            costSum.heightAnchor.constraint(equalToConstant: 25)
        ])
    }

    func createOrdersLabel(text: String, font: UIFont?, aligment: NSTextAlignment) -> UILabel {
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
