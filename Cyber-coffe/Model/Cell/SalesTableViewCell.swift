//
//  ScheduleTableViewCell.swift
//  
//
//  Created by Леонід Квіт on 05.11.2021.
//

import UIKit

class SalesTableViewCell: UITableViewCell {
    
    lazy var goodsName = createSalesLabel(text: "05.09.21", font: .avenirNext20(), aligment: .left)
    lazy var salesSum = createSalesLabel(text: "640", font: .avenirNextDemiBold20(), aligment: .left)
    lazy var salesLabel = createSalesLabel(text: "Продажа:", font: .avenirNext14(), aligment: .right)
    lazy var cashSum = createSalesLabel(text: "230", font: .avenirNextDemiBold20(), aligment: .left)
    lazy var cashLabel = createSalesLabel(text: "Касса:", font: .avenirNext14(), aligment: .right)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.accessoryType = .disclosureIndicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            setConstraints()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setConstraints() {
        
        self.addSubview(goodsName)
        NSLayoutConstraint.activate([
            goodsName.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            goodsName.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            goodsName.widthAnchor.constraint(equalToConstant: 200),
            goodsName.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        let salesStackView = UIStackView(arrangedSubviews: [salesLabel, salesSum], axis: .horizontal, spacing: 5, distribution: .fillEqually)

        self.addSubview(salesStackView)
        NSLayoutConstraint.activate([
            salesStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            salesStackView.leadingAnchor.constraint(equalTo: goodsName.trailingAnchor, constant: 5),
            salesStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -25),
            salesStackView.heightAnchor.constraint(equalToConstant: 25),
        ])
        
        let cashStackView = UIStackView(arrangedSubviews: [cashLabel, cashSum], axis: .horizontal, spacing: 5, distribution: .fillEqually)

        self.addSubview(cashStackView)
        NSLayoutConstraint.activate([
            cashStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            cashStackView.leadingAnchor.constraint(equalTo: goodsName.trailingAnchor, constant: 5),
            cashStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -25),
            cashStackView.heightAnchor.constraint(equalToConstant: 25),
        ])
        
//        self.addSubview(lessonTime)
//        NSLayoutConstraint.activate([
//            lessonTime.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
//            lessonTime.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
//            lessonTime.widthAnchor.constraint(equalToConstant: 100),
//            lessonTime.heightAnchor.constraint(equalToConstant: 25),
//        ])
//
//        let bottomStackView = UIStackView(arrangedSubviews: [typeLabel, lessonType, buildingLabel, lessonBuilding, audLabel, lessonAud], axis: .horizontal, spacing: 5, distribution: .fillProportionally)
//
//        self.addSubview(bottomStackView)
//        NSLayoutConstraint.activate([
//            bottomStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
//            bottomStackView.leadingAnchor.constraint(equalTo: lessonTime.trailingAnchor, constant: 5),
//            bottomStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
//            bottomStackView.heightAnchor.constraint(equalToConstant: 25),
//        ])
        
    }
    
    func createSalesLabel(text: String, font: UIFont?, aligment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = .black
        label.textAlignment = aligment
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.backgroundColor = .systemRed
        
        return label
    }
}
