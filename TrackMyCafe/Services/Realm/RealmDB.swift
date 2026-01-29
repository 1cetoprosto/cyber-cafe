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
    func fetchProducts() -> [RealmProductModel]
    func fetchProducts(forDate date: Date) -> [RealmProductModel]
    func fetchProduct(forDate date: Date, withName name: String) -> RealmProductModel?
    func fetchProducts(withOrderId id: String) -> [RealmProductModel]
    
    func updateOrder(model: RealmOrderModel, date: Date, type: String, total: Double, cashAmount: Double, cardAmount: Double)
    func fetchOrders() -> [RealmOrderModel]
    func fetchOrderSections() -> [(date: Date, items: [RealmOrderModel])]
    func fetchOrder(byId id: String) -> RealmOrderModel?
    func fetchOrders(forDate date: Date, ofType type: String?) -> [RealmOrderModel]
    
    func updateProductPrice(model: RealmProductsPriceModel, name: String, price: Double, recipe: [RecipeItemModel])
    func fetchProductPrices() -> [RealmProductsPriceModel]
    func fetchProductPrice(byId id: String) -> RealmProductsPriceModel?
    
    func updateCost(model: RealmCostModel, date: Date, name: String, sum: Double)
    func fetchCosts() -> [RealmCostModel]
    func fetchCostSections() -> [(date: Date, items: [RealmCostModel])]
    func fetchCost(byId id: String) -> RealmCostModel?
    
    func updateType(model: RealmTypeModel, type: String)
    func fetchTypes() -> [RealmTypeModel]
    func fetchType(byId id: String) -> RealmTypeModel?
    
    func deleteAllData(completion: @escaping (Bool) -> Void)
}

