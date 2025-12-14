//
//  OrderListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol OrderListViewModelType {
    func getOrders(completion: @escaping () -> Void)
    
    func numberOfSections() -> Int
    func numberOfRowInSection(for section: Int) -> Int
    func titleForHeaderInSection(for section: Int) -> String
    func cellViewModel(for indexPath: IndexPath) -> OrderListItemViewModelType?
    
    func viewModelForSelectedRow() -> OrderDetailsViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
    
    func deleteOrderModel(atIndexPath indexPath: IndexPath)
}
