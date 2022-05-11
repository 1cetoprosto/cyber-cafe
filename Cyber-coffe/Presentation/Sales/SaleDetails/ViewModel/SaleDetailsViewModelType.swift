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
    var typeOfDonation: String { get }
    var newModel: Bool { get set }
    
    func numberOfRowsInComponent(component: Int) -> Int
    //func setTypeOfDonation(row: Int, component: Int)
    func titleForRow(row: Int, component: Int) -> String?
    func selectRow(atRow: Int)
    
    func isExist(date: Date, type: String) -> Bool
    func saveSales(date: Date, typeOfDonation: String?, salesCash: String?, salesSum: String?)
    func updateSales(date: Date, typeOfDonation: String?, salesCash: String?, salesSum: String?)
    
    //func saveSalesGood(date: Date, good: String?, qty: Int?, price: Double?, sum: Double?)
    
    /// var age: Box<String?> { get }
}
