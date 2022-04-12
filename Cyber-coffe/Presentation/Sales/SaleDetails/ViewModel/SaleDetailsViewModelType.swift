//
//  SaleDetailsViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol SaleDetailsViewModelType {
    var date: Date { get }
    var moneyLabel: String { get }
    var moneyTextfield: String { get }
    var saleLabel: String { get }
    var salesCash: Double { get }
    var salesSum: Double { get }
    var newModel: Bool { get set }
    
    func saveSales(date: Date, salesCash: String?, salesSum: String?)
    func updateSales(date: Date, salesCash: String?, salesSum: String?)
    
    //func saveSalesGood(date: Date, good: String?, qty: Int?, price: Double?, sum: Double?)
    
    /// var age: Box<String?> { get }
}
