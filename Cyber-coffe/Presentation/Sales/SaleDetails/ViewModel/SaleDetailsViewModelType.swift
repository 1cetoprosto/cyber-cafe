//
//  SaleDetailsViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol SaleDetailsViewModelType {
    var moneyLabel: String { get }
    var moneyTextfield: String { get }
    var saleLabel: String { get }
    var salesCash: Double { get }
    var salesSum: Double { get }
    //var age: Box<String?> { get }
}
