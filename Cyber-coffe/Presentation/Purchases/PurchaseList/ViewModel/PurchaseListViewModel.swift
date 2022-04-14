//
//  PurchaseListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class PurchaseListViewModel: PurchaseListViewModelType {
    
    private var selectedIndexPath: IndexPath?
    private var purchases: [PurchaseModel]?
    
    func getPurchases(completion: @escaping () -> ()) {
        purchases = DatabaseManager.shared.fetchPurchases()
        completion()
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        guard let purchases = self.purchases else { return 0 }
        return purchases.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> PurchaseListItemViewModelType? {
        guard let purchases = self.purchases else { return nil }
        let purchase = purchases[indexPath.row]
        return PurchaseListItemViewModel(purchase: purchase)
    }

    func viewModelForSelectedRow() -> PurchaseDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              let purchases = self.purchases else { return nil }
        let purchase = purchases[selectedIndexPath.row]
        return PurchaseDetailsViewModel(purchase: purchase)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    func getPurchase() -> PurchaseModel? {
        guard let selectedIndexPath = selectedIndexPath,
              let purchases = self.purchases else { return nil }
        return purchases[selectedIndexPath.row]
    }
    
}
