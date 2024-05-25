//
//  SaleGoodListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

protocol SaleGoodListViewModelType {
    func getSaleGoods(withIdDailySale id: String, completion: @escaping() -> ())
    
    func numberOfRowInSection(for section: Int) -> Int
    func cellViewModel(for indexPath: IndexPath) -> SaleGoodListItemViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
    
    func setQuantity(tag: Int, quantity: Int)
    func getQuantity() -> Double
    func totalSum() -> String
    
    func saveSalesGood(withDailySaleId dailySaleId: String, date: Date)
    func updateSalesGood(date: Date)
}
