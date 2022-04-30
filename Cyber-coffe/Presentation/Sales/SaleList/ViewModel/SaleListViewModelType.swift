//
//  SaleListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol SaleListViewModelType {
    func getSales(completion: @escaping() -> ())
    
    func numberOfSections() -> Int
    func numberOfRowInSection(for section: Int) -> Int
    func titleForHeaderInSection(for section: Int) -> String
    func cellViewModel(for indexPath: IndexPath) -> SaleListItemViewModelType?
    
    func viewModelForSelectedRow() -> SaleDetailsViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
    
    func deleteSaleModel(atIndexPath indexPath: IndexPath)
}
