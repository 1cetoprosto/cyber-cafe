//
//  DomainDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.05.2024.
//

import Foundation

protocol DomainDB {
    // Асинхронний метод для оновлення даних про продажі
    func updateSaleGood(model: SaleGoodModel, date: Date, name: String, quantity: Int, price: Double, sum: Double)
    
    // Асинхронний метод для отримання списку продаж за певну дату
    func fetchSaleGood(forDate date: Date, completion: @escaping ([SaleGoodModel]) -> Void)
    
    // Асинхронний метод для отримання продажів за певну дату та назву
    func fetchSaleGood(forDate date: Date, withName name: String, completion: @escaping (SaleGoodModel?) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про продажі
    func updateSales(model: DailySalesModel, date: Date, incomeType: String, total: Double, cashAmount: Double, cardAmount: Double)
    func fetchSales(completion: @escaping ([DailySalesModel]) -> Void)
    func fetchSectionsOfSales(completion: @escaping ([(date: Date, items: [DailySalesModel])]) -> Void)
    func fetchSales(forDate date: Date, ofType type: String?, completion: @escaping ([DailySalesModel]) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про товари
    func updateGoodsPrice(model: GoodsPriceModel, name: String, price: Double)
    func fetchGoodsPrice(completion: @escaping ([GoodsPriceModel]) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про покупки
    func updatePurchase(model: PurchaseModel, date: Date, name: String, sum: Double)
    func fetchPurchases(completion: @escaping ([PurchaseModel]) -> Void)
    func fetchSectionsOfPurchases(completion: @escaping ([(date: Date, items: [PurchaseModel])]) -> Void)
    
    // Асинхронні методи для оновлення та отримання даних про типи доходів
    func updateIncomeType(model: IncomeTypeModel, type: String)
    func fetchIncomeTypes(completion: @escaping ([IncomeTypeModel]) -> Void)
    
    // Асинхронний метод для видалення всіх даних
    func deleteAllData(completion: @escaping () -> Void)
}
