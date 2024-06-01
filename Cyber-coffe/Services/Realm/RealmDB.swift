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
    
    func updateProduct(model: RealmProductModel, date: Date, name: String, quantity: Int, price: Double, sum: Double)
    func fetchProduct(forDate date: Date) -> [RealmProductModel]
    func fetchProduct(forDate date: Date, withName name: String) -> RealmProductModel
    
    func updateOrders(model: RealmOrderModel, date: Date, type: String, total: Double, cashAmount: Double, cardAmount: Double)
    func fetchOrders() -> [RealmOrderModel]
    func fetchSectionsOfOrders() -> [(date: Date, items: [RealmOrderModel])]
    func fetchOrders(forDate date: Date, ofType type: String?) -> [RealmOrderModel]
    
    func updateProductsPrice(model: RealmProductsPriceModel, name: String, price: Double)
    func fetchProductsPrice() -> [RealmProductsPriceModel]
    
    func updateCost(model: RealmCostModel, date: Date, name: String, sum: Double)
    func fetchCosts() -> [RealmCostModel]
    func fetchSectionsOfCosts() -> [(date: Date, items: [RealmCostModel])]
    
    func updateType(model: RealmTypeModel, type: String)
    func fetchTypes() -> [RealmTypeModel]
    
    func deleteAllData(completion: @escaping () -> Void)
}
