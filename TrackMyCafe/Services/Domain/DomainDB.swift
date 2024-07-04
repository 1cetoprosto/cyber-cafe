//
//  DomainDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.05.2024.
//

import Foundation

protocol DomainDB {
    // Асинхронний метод для оновлення даних про продажі
    func updateProduct(model: ProductOfOrderModel, date: Date, name: String, quantity: Int, price: Double, sum: Double)
    
    // Асинхронний метод для отримання списку продаж за певну дату
    func fetchProduct(forDate date: Date, completion: @escaping ([ProductOfOrderModel]) -> Void)
    
    // Асинхронний метод для отримання продажів за певну дату та назву
    func fetchProduct(forDate date: Date, withName name: String, completion: @escaping (ProductOfOrderModel?) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про продажі
    func updateOrders(model: OrderModel, date: Date, type: String, total: Double, cashAmount: Double, cardAmount: Double)
    func fetchOrders(completion: @escaping ([OrderModel]) -> Void)
    func fetchSectionsOfOrders(completion: @escaping ([(date: Date, items: [OrderModel])]) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про товари
    func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double)
    func fetchProductsPrice(completion: @escaping ([ProductsPriceModel]) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про покупки
    func updateCost(model: CostModel, date: Date, name: String, sum: Double)
    func fetchCosts(completion: @escaping ([CostModel]) -> Void)
    func fetchSectionsOfCosts(completion: @escaping ([(date: Date, items: [CostModel])]) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про типи доходів
    func updateType(model: TypeModel, type: String)
    func fetchTypes(completion: @escaping ([TypeModel]) -> Void)
    
    // Асинхронний метод для видалення всіх даних
    func deleteAllData(completion: @escaping () -> Void)
}
