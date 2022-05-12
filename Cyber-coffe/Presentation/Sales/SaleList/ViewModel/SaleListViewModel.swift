//
//  SaleListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 22.03.2022.
//

import Foundation

class SaleListViewModel: SaleListViewModelType {
    
    private var selectedIndexPath: IndexPath?
    //private var sales: [SalesModel]? // Results<SalesModel>!
    private var sectionsSales: [(date: Date, items: [SalesModel])]?
    
    func getSales(completion: @escaping () -> ()) {
        //sales = DatabaseManager.shared.fetchSales()
        sectionsSales = DatabaseManager.shared.fetchSectionsSales()
        
        completion()
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
        return SaleListItemViewModel(sale: sale)
    }
    
    func viewModelForSelectedRow() -> SaleDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              let sectionsSales = self.sectionsSales else { return nil }
        let sale = sectionsSales[selectedIndexPath.section].items[selectedIndexPath.row]
        
        return SaleDetailsViewModel(sale: sale)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    func getSale(atIndexPath indexPath: IndexPath) -> SalesModel? {
        guard let sectionsSales = self.sectionsSales else { return nil }
        
        return sectionsSales[indexPath.section].items[indexPath.row]
    }
    
    func deleteSaleModel(atIndexPath indexPath: IndexPath) {
        guard let model = getSale(atIndexPath: indexPath) else { return }
        SaleGoodListViewModel.deleteSalesGood(date: model.salesDate)
        DatabaseManager.shared.deleteSalesModel(model: model)
    }
}
