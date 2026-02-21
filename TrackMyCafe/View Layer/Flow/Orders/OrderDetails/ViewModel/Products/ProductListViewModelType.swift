//
//  ProductListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

protocol ProductListViewModelType {
    func getProducts(withIdOrder id: String, completion: @escaping () -> Void)
    
    func numberOfRowInSection(for section: Int) -> Int
    func cellViewModel(for indexPath: IndexPath) -> ProductListItemViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
    
    func setQuantity(tag: Int, quantity: Int)
    func getQuantity() -> Double
    func getTotalAmount() -> Double
    func totalSum() -> String
    
    func saveOrder(withOrderId orderId: String, date: Date, completion: @escaping (Bool) -> Void)
    func updateOrder(date: Date, completion: @escaping (Bool) -> Void)
    
    func validateStock(completion: @escaping ([StockWarning]) -> Void)
    func deductStock(completion: @escaping (Bool) -> Void)
}
