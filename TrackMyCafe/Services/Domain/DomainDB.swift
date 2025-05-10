//
//  DomainDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.05.2024.
//

import Foundation

protocol DomainDB {
    // Asynchronous method for updating sales data
    func updateProduct(model: ProductOfOrderModel, date: Date, name: String, quantity: Int, price: Double, sum: Double)
    
    // Asynchronous method for getting a sales list for a specific date
    func fetchProduct(forDate date: Date, completion: @escaping ([ProductOfOrderModel]) -> Void)
    
    // Asynchronous method for getting sales for a specific date and title
    func fetchProduct(forDate date: Date, withName name: String, completion: @escaping (ProductOfOrderModel?) -> Void)
    
    // Asynchronous methods for updating and retrieving sales data
    func updateOrders(model: OrderModel, date: Date, type: String, total: Double, cashAmount: Double, cardAmount: Double)
    func fetchOrders(completion: @escaping ([OrderModel]) -> Void)
    func fetchSectionsOfOrders(completion: @escaping ([(date: Date, items: [OrderModel])]) -> Void)
    
    // Asynchronous methods for updating and retrieving product data
    func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double)
    func fetchProductsPrice(completion: @escaping ([ProductsPriceModel]) -> Void)
    
    // Asynchronous methods for updating and retrieving purchase data
    func updateCost(model: CostModel, date: Date, name: String, sum: Double)
    func fetchCosts(completion: @escaping ([CostModel]) -> Void)
    func fetchSectionsOfCosts(completion: @escaping ([(date: Date, items: [CostModel])]) -> Void)
    
    // Asynchronous methods for updating and retrieving data on income types
    func updateType(model: TypeModel, type: String)
    func fetchTypes(completion: @escaping ([TypeModel]) -> Void)
    
    // Asynchronous method for deleting data from the active database
    func deleteActiveDatabaseData(completion: @escaping (Bool) -> Void)
}
