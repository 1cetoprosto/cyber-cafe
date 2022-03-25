//
//  SaleListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 22.03.2022.
//

import Foundation
import RealmSwift

class SaleListViewModel: SaleListViewModelType {

    private var selectedIndexPath: IndexPath?
    private var sales: [SalesModel]? // Results<SalesModel>!
    
    func getSales(completion: @escaping () -> ()) {
        //let databaseManager = DatabaseManager()
        sales = DatabaseManager.shared.fetchSales()
    }
    
    func numberOfSections() -> Int {
        return 0
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        guard let sales = self.sales else { return 0 }
        return sales.count
    }
    
    func titleForHeaderInSection(for section: Int) -> String {
        return "Section"
    }
    
    func cellViewModel(for indexPath: IndexPath) -> SaleListItemViewModelType? {
        guard let sales = self.sales else { return nil }
        let sale = sales[indexPath.row]
        return SaleListItemViewModel(sale: sale)
    }
    
    func viewModelForSelectedRow() -> SaleDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              let sales = self.sales else { return nil }
        //let sale = sales[selectedIndexPath.row]
        return nil//SaleDetailsViewModel
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    
}
