//
//  RealmDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation
import RealmSwift

// MARK: - Protocol RealmDB

protocol RealmDB {
    func save<T: Object>(model object: T)
    func delete<T: Object>(model object: T)
    
    func updateSaleGood(model: RealmSaleGoodModel, date: Date, name: String, quantity: Int, price: Double, sum: Double)
    func fetchSaleGood(forDate date: Date) -> [RealmSaleGoodModel]
    func fetchSaleGood(forDate date: Date, withName name: String) -> RealmSaleGoodModel
    
    func updateSales(model: RealmDailySalesModel, date: Date, incomeType: String, total: Double, cashAmount: Double, cardAmount: Double)
    func fetchSales() -> [RealmDailySalesModel]
    func fetchSectionsOfSales() -> [(date: Date, items: [RealmDailySalesModel])]
    func fetchSales(forDate date: Date, ofType type: String?) -> [RealmDailySalesModel]
    
    func updateGoodsPrice(model: RealmGoodsPriceModel, name: String, price: Double)
    func fetchGoodsPrice() -> [RealmGoodsPriceModel]
    
    func updatePurchase(model: RealmPurchaseModel, date: Date, name: String, sum: Double)
    func fetchPurchases() -> [RealmPurchaseModel]
    func fetchSectionsOfPurchases() -> [(date: Date, items: [RealmPurchaseModel])]
    
    func updateIncomeType(model: RealmIncomeTypeModel, type: String)
    func fetchIncomeTypes() -> [RealmIncomeTypeModel]
    
    func deleteAllData(completion: @escaping () -> Void)
}
