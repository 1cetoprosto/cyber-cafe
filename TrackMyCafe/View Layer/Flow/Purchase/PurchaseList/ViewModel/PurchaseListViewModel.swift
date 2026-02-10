//
//  PurchaseListViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

protocol PurchaseListViewModelType {
    func getPurchases(completion: @escaping () -> Void)
    func numberOfSections() -> Int
    func titleForHeaderInSection(for section: Int) -> String
    func numberOfRowInSection(for section: Int) -> Int
    func cellViewModel(for indexPath: IndexPath) -> PurchaseListItemViewModelType?
    // func selectRow(atIndexPath indexPath: IndexPath) // For details later
}

class PurchaseListViewModel: PurchaseListViewModelType {
    private var sectionsPurchases: [(date: Date, items: [PurchaseModel])] = []
    private var ingredientsCache: [String: String] = [:] // id: name
    
    func getPurchases(completion: @escaping () -> Void) {
        // 1. Fetch Ingredients for names
        DomainDatabaseService.shared.fetchIngredients { [weak self] ingredients in
            ingredients.forEach { self?.ingredientsCache[$0.id] = $0.name }
            
            // 2. Fetch Purchases
            DomainDatabaseService.shared.fetchPurchases { [weak self] purchases in
                self?.groupPurchasesByDate(purchases)
                completion()
            }
        }
    }
    
    private func groupPurchasesByDate(_ purchases: [PurchaseModel]) {
        let grouped = Dictionary(grouping: purchases) { (purchase) -> Date in
            return Calendar.current.startOfDay(for: purchase.date)
        }
        
        let sortedKeys = grouped.keys.sorted(by: >)
        
        self.sectionsPurchases = sortedKeys.map { date in
            (date: date, items: grouped[date]?.sorted(by: { $0.date > $1.date }) ?? [])
        }
    }
    
    func numberOfSections() -> Int {
        return sectionsPurchases.count
    }
    
    func titleForHeaderInSection(for section: Int) -> String {
        let date = sectionsPurchases[section].date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        return sectionsPurchases[section].items.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> PurchaseListItemViewModelType? {
        let purchase = sectionsPurchases[indexPath.section].items[indexPath.row]
        let ingredientName = ingredientsCache[purchase.ingredientId] ?? "Unknown Ingredient"
        
        return PurchaseListItemViewModel(purchase: purchase, ingredientName: ingredientName)
    }
}
