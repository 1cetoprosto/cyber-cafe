//
//  OrderListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 22.03.2022.
//

import Foundation

class OrderListViewModel: OrderListViewModelType {
    
    private var selectedIndexPath: IndexPath?
    private var sectionsOrders: [(date: Date, items: [OrderModel])]?
    
    func getOrders(completion: @escaping () -> Void) {
        DomainDatabaseService.shared.fetchSectionsOfOrders { [weak self] sectionsOrders in
            self?.sectionsOrders = sectionsOrders
            completion()
        }
    }
    
    func numberOfSections() -> Int {
        guard let sectionsOrders = self.sectionsOrders else { return 0 }
        
        return sectionsOrders.count
    }
    
    func titleForHeaderInSection(for section: Int) -> String {
        guard let sectionsOrders = self.sectionsOrders else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        
        return dateFormatter.string(from: sectionsOrders[section].date)
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        guard let sectionsOrders = self.sectionsOrders else { return 0 }
        return sectionsOrders[section].items.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> OrderListItemViewModelType? {
        guard let sectionsOrders = self.sectionsOrders else { return nil }
        let order = sectionsOrders[indexPath.section].items[indexPath.row]
        return OrderListItemViewModel(model: order)
    }
    
    func viewModelForSelectedRow() -> OrderDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              let sectionsOrders = self.sectionsOrders else { return nil }
        let order = sectionsOrders[selectedIndexPath.section].items[selectedIndexPath.row]
        
        return OrderDetailsViewModel(model: order)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    func getOrder(atIndexPath indexPath: IndexPath) -> OrderModel? {
        guard let sectionsOrders = self.sectionsOrders else { return nil }
        
        return sectionsOrders[indexPath.section].items[indexPath.row]
    }
    
    func deleteOrderModel(atIndexPath indexPath: IndexPath) {
        guard let model = getOrder(atIndexPath: indexPath) else { return }
        ProductListViewModel.deleteOrder(withOrderId: model.id, date: model.date)
        
        DomainDatabaseService.shared.deleteOrder(order: model) { success in
            if success {
                print("Orders deleted successfully")
            } else {
                print("Failed to delete orders")
            }
        }
        
        
    }
}
