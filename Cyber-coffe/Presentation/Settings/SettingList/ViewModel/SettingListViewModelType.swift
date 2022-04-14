//
//  SettingListViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import Foundation

protocol SettingListViewModelType: AnyObject {
    func getSettings(completion: @escaping() -> ())
    
    //func numberOfSections() -> Int
    func numberOfRowInSection(for section: Int) -> Int
    //func titleForHeaderInSection(for section: Int) -> String
    func cellViewModel(for indexPath: IndexPath) -> SettingListViewModelType?
    
    //func viewModelForSelectedRow() -> PurchaseDetailsViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
}
