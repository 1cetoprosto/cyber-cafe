//
//  ProductListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

protocol ProductListViewModelType {
    func getProducts(withIdOrder id: String, completion: @escaping() -> ())
    
    func numberOfRowInSection(for section: Int) -> Int
    func cellViewModel(for indexPath: IndexPath) -> ProductListItemViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
    
    func setQuantity(tag: Int, quantity: Int)
    func getQuantity() -> Double
    func totalSum() -> String
    
    func saveOrder(withOrderId orderId: String, date: Date)
    func updateOrder(date: Date)
}
