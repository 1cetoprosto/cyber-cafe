//
//  SaleListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 22.03.2022.
//

import Foundation

class SaleListViewModel: SaleListViewModelType {
    
    private var selectedIndexPath: IndexPath?
    private var sectionsSales: [(date: Date, items: [DailySalesModel])]?
    
    func getSales(completion: @escaping () -> Void) {
        DomainDatabaseService.shared.fetchSectionsOfSales { [weak self] sectionsSales in
            self?.sectionsSales = sectionsSales
            completion()
        }
    }
    
    func numberOfSections() -> Int {
        guard let sectionsSales = self.sectionsSales else { return 0 }
        
        return sectionsSales.count
    }
    
    func titleForHeaderInSection(for section: Int) -> String {
        guard let sectionsSales = self.sectionsSales else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        
        return dateFormatter.string(from: sectionsSales[section].date)
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        guard let sectionsSales = self.sectionsSales else { return 0 }
        return sectionsSales[section].items.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> SaleListItemViewModelType? {
        guard let sectionsSales = self.sectionsSales else { return nil }
        let sale = sectionsSales[indexPath.section].items[indexPath.row]
        return SaleListItemViewModel(model: sale)
    }
    
    func viewModelForSelectedRow() -> SaleDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              let sectionsSales = self.sectionsSales else { return nil }
        let sale = sectionsSales[selectedIndexPath.section].items[selectedIndexPath.row]
        
        return SaleDetailsViewModel(model: sale)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    func getSale(atIndexPath indexPath: IndexPath) -> DailySalesModel? {
        guard let sectionsSales = self.sectionsSales else { return nil }
        
        return sectionsSales[indexPath.section].items[indexPath.row]
    }
    
    func deleteSaleModel(atIndexPath indexPath: IndexPath) {
        guard let model = getSale(atIndexPath: indexPath) else { return }
        SaleGoodListViewModel.deleteSalesGood(withDailySaleId: model.id, date: model.date)
        
        DomainDatabaseService.shared.deleteDailySale(sale: model) { success in
            if success {
                print("Sales deleted successfully")
            } else {
                print("Failed to delete sales")
            }
        }
        
        
    }
}
