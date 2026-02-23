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
    func purchase(at indexPath: IndexPath) -> PurchaseModel
    func availableIngredients() -> [(id: String, name: String)]
    func applyFilter(
        dateRange: ClosedRange<Date>?,
        ingredientId: String?,
        completion: @escaping () -> Void
    )
}

class PurchaseListViewModel: PurchaseListViewModelType {
    private var allPurchases: [PurchaseModel] = []
    private var sectionsPurchases: [(date: Date, items: [PurchaseModel])] = []
    private var ingredientsCache: [String: String] = [:]  // id: name
    private let dbService: DomainDB
    private var currentDateRange: ClosedRange<Date>?
    private var currentIngredientId: String?

    init(dbService: DomainDB = DomainDatabaseService.shared) {
        self.dbService = dbService
    }

    func getPurchases(completion: @escaping () -> Void) {
        // 1. Fetch Ingredients for names
        dbService.fetchIngredients { [weak self] ingredients in
            ingredients.forEach { self?.ingredientsCache[$0.id] = $0.name }

            // 2. Fetch Purchases
            self?.dbService.fetchPurchases { [weak self] purchases in
                self?.allPurchases = purchases
                self?.applyCurrentFilters()
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

    func availableIngredients() -> [(id: String, name: String)] {
        let ids = Set(allPurchases.map { $0.ingredientId })
        let items = ids.map { (id: $0, name: ingredientsCache[$0] ?? $0) }
        return items.sorted(by: { left, right in
            left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        })
    }

    func purchase(at indexPath: IndexPath) -> PurchaseModel {
        return sectionsPurchases[indexPath.section].items[indexPath.row]
    }

    func applyFilter(
        dateRange: ClosedRange<Date>?,
        ingredientId: String?,
        completion: @escaping () -> Void
    ) {
        currentDateRange = dateRange
        currentIngredientId = ingredientId
        applyCurrentFilters()
        completion()
    }

    private func applyCurrentFilters() {
        var filtered = allPurchases

        if let range = currentDateRange {
            filtered = filtered.filter { range.contains($0.date) }
        }

        if let ingredientId = currentIngredientId, !ingredientId.isEmpty {
            filtered = filtered.filter { $0.ingredientId == ingredientId }
        }

        groupPurchasesByDate(filtered)
    }
}
