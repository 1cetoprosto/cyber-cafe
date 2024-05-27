//
//  SaleDetailsViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol SaleDetailsViewModelType {
    var id: String { get }
    var date: Date { get }
    var cashLabel: String { get }
    var cardLabel: String { get }
    var cashTextfield: String { get }
    var cardTextfield: String { get }
    var saleLabel: String { get }
    var cash: Double { get }
    var card: Double { get }
    var sum: Double { get }
    var incomeType: String { get }
    var isNewModel: Bool { get set }
    
    func numberOfRowsInComponent(component: Int) -> Int
    func titleForRow(row: Int, component: Int) -> String?
    func selectRow(atRow: Int)
    
    func isExist(id: String, completion: @escaping (Bool) -> Void)
    func saveSales(id: String, date: Date, incomeType: String?, cash: String?, card: String?, sum: String?, completion: @escaping () -> Void)
    func updateSales(id: String, date: Date, incomeType: String?, cash: String?, card: String?, sum: String?, completion: @escaping () -> Void)
    
    func verifyRequiredData(completion: @escaping (Bool) -> Void)
}
