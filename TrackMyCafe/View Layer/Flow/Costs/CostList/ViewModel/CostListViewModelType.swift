//
//  CostListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol CostListViewModelType: AnyObject {
    func getCosts(completion: @escaping() -> ())
    
    func numberOfSections() -> Int
    func numberOfRowInSection(for section: Int) -> Int
    func titleForHeaderInSection(for section: Int) -> String
    func cellViewModel(for indexPath: IndexPath) -> CostListItemViewModelType?
    
    func viewModelForSelectedRow() -> CostDetailsViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
    
    func deleteCostModel(atIndexPath indexPath: IndexPath)
}
