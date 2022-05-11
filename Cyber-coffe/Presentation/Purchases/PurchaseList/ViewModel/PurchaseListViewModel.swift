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
    private var sectionsPurchases: [(date: Date, items: [PurchaseModel])]?
    
    func getPurchases(completion: @escaping () -> ()) {
        purchases = DatabaseManager.shared.fetchPurchases()
        sectionsPurchases = DatabaseManager.shared.fetchSectionsPurchases()
        
        completion()
    }
    
    func numberOfSections() -> Int {
        guard let sectionsPurchases = self.sectionsPurchases else { return 0 }
        return sectionsPurchases.count
    }
    
    func titleForHeaderInSection(for section: Int) -> String {
        guard let sectionsPurchases = self.sectionsPurchases else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter.string(from: sectionsPurchases[section].date)
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        //guard let purchases = self.purchases else { return 0 }
        guard let sectionsPurchases = self.sectionsPurchases else { return 0 }
        
        return sectionsPurchases[section].items.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> PurchaseListItemViewModelType? {
        //guard let purchases = self.purchases else { return nil }
        guard let sectionsPurchases = self.sectionsPurchases else { return nil }
        //let purchase = purchases[indexPath.row]
        let purchase = sectionsPurchases[indexPath.section].items[indexPath.row]
        return PurchaseListItemViewModel(purchase: purchase)
    }

    func viewModelForSelectedRow() -> PurchaseDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              //let purchases = self.purchases else { return nil }
               let sectionsPurchases = self.sectionsPurchases else { return nil }
        //let purchase = purchases[selectedIndexPath.row]
        let purchase = sectionsPurchases[selectedIndexPath.section].items[selectedIndexPath.row]
        return PurchaseDetailsViewModel(purchase: purchase)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    private func getPurchaseModel(atIndexPath indexPath: IndexPath) -> PurchaseModel? {
        //guard let purchases = self.purchases else { return nil }
        guard let sectionsPurchases = self.sectionsPurchases else { return nil }
        
        //return purchases[indexPath.row]
        return sectionsPurchases[indexPath.section].items[indexPath.row]
    }
    
    func deletePurchaseModel(atIndexPath indexPath: IndexPath) {
        guard let model = getPurchaseModel(atIndexPath: indexPath) else { return }
        DatabaseManager.shared.deletePurchaseModel(model: model)
    }
    
}
