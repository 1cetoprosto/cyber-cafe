//
//  PurchaseListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class PurchaseListViewModel: PurchaseListViewModelType {
    private var selectedIndexPath: IndexPath?
    private var sectionsPurchases: [(date: Date, items: [PurchaseModel])]?
    
    func getPurchases(completion: @escaping () -> ()) {
        DomainDatabaseService.shared.fetchSectionsOfPurchases { sectionsPurchases in
            self.sectionsPurchases = sectionsPurchases
            completion()
        }
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
        guard let sectionsPurchases = self.sectionsPurchases else { return 0 }
        
        return sectionsPurchases[section].items.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> PurchaseListItemViewModelType? {
        guard let sectionsPurchases = self.sectionsPurchases else { return nil }
        let purchase = sectionsPurchases[indexPath.section].items[indexPath.row]
        
        return PurchaseListItemViewModel(purchase: purchase)
    }
    
    func viewModelForSelectedRow() -> PurchaseDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              let sectionsPurchases = self.sectionsPurchases else { return nil }
        let purchase = sectionsPurchases[selectedIndexPath.section].items[selectedIndexPath.row]
        
        return PurchaseDetailsViewModel(purchase: purchase)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    private func getPurchaseModel(atIndexPath indexPath: IndexPath) -> PurchaseModel? {
        guard let sectionsPurchases = self.sectionsPurchases else { return nil }
        
        return sectionsPurchases[indexPath.section].items[indexPath.row]
    }
    
    func deletePurchaseModel(atIndexPath indexPath: IndexPath) {
        guard let model = getPurchaseModel(atIndexPath: indexPath) else { return }
        
        DomainDatabaseService.shared.deletePurchase(purchase: model) { success in
            if success {
                print("Purchases deleted successfully")
            } else {
                print("Failed to delete purchases")
            }
        }
    }
    
}
