//
//  CostListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class CostListViewModel: CostListViewModelType, Loggable {
    private var selectedIndexPath: IndexPath?
    private var sectionsCosts: [(date: Date, items: [CostModel])]?
    
    func getCosts(completion: @escaping () -> ()) {
        DomainDatabaseService.shared.fetchSectionsOfCosts { sectionsCosts in
            self.sectionsCosts = sectionsCosts
            completion()
        }
    }
    
    func numberOfSections() -> Int {
        guard let sectionsCosts = self.sectionsCosts else { return 0 }
        
        return sectionsCosts.count
    }
    
    func titleForHeaderInSection(for section: Int) -> String {
        guard let sectionsCosts = self.sectionsCosts else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        
        return dateFormatter.string(from: sectionsCosts[section].date)
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        guard let sectionsCosts = self.sectionsCosts else { return 0 }
        
        return sectionsCosts[section].items.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> CostListItemViewModelType? {
        guard let sectionsCosts = self.sectionsCosts else { return nil }
        let cost = sectionsCosts[indexPath.section].items[indexPath.row]
        
        return CostListItemViewModel(cost: cost)
    }
    
    func viewModelForSelectedRow() -> CostDetailsViewModelType? {
        guard let selectedIndexPath = selectedIndexPath,
              let sectionsCosts = self.sectionsCosts else { return nil }
        let cost = sectionsCosts[selectedIndexPath.section].items[selectedIndexPath.row]
        
        return CostDetailsViewModel(cost: cost, dataService: DomainCostDataService())
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    private func getCostModel(atIndexPath indexPath: IndexPath) -> CostModel? {
        guard let sectionsCosts = self.sectionsCosts else { return nil }
        
        return sectionsCosts[indexPath.section].items[indexPath.row]
    }
    
    func deleteCostModel(atIndexPath indexPath: IndexPath) {
        guard let model = getCostModel(atIndexPath: indexPath) else { return }
        
        DomainDatabaseService.shared.deleteCost(model: model) { success in
            if success {
                self.logger.notice("Costs \(model.id) deleted successfully")
            } else {
                self.logger.error("Failed to delete costs \(model.id)")
            }
        }
    }
    
}
