//
//  PurchaseListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol PurchaseListViewModelType: AnyObject {
    func getPurchases(completion: @escaping() -> ())
    
    //func numberOfSections() -> Int
    func numberOfRowInSection(for section: Int) -> Int
    //func titleForHeaderInSection(for section: Int) -> String
    func cellViewModel(for indexPath: IndexPath) -> PurchaseListItemViewModelType?
    
    func viewModelForSelectedRow() -> PurchaseDetailsViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
    
    func deletePurchaseModel(atIndexPath indexPath: IndexPath)
}
