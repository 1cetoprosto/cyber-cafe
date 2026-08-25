//
//  InventoryAdjustmentListViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import Foundation

struct InventoryAdjustmentListItemViewModel: Identifiable {
    let id: String
    let dateText: String
    let ingredientName: String
    let unitText: String
    let deltaText: String
    let deltaSign: FloatingPointSign
    let reasonText: String?
    let sourceText: String
    let bulkSessionId: String?
}

protocol InventoryAdjustmentListViewModelProtocol: AnyObject {
    var onDataUpdated: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var isLoading: ((Bool) -> Void)? { get set }

    var items: [InventoryAdjustmentListItemViewModel] { get }
    var sections: [(date: Date, items: [InventoryAdjustmentListItemViewModel])] { get }

    func fetchData()
    func setFilter(startDate: Date?, endDate: Date?, ingredientId: String?)
    func setFilter(bulkSessionId: String?)
    func adjustment(at indexPath: IndexPath) -> InventoryAdjustmentModel?
}

final class InventoryAdjustmentListViewModel: InventoryAdjustmentListViewModelProtocol {

    // MARK: - Hooks

    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var isLoading: ((Bool) -> Void)?

    // MARK: - Output

    private(set) var items: [InventoryAdjustmentListItemViewModel] = []
    private(set) var sections: [(date: Date, items: [InventoryAdjustmentListItemViewModel])] = []

    // MARK: - State

    private var rawAdjustments: [InventoryAdjustmentModel] = []
    private var ingredientsById: [String: IngredientModel] = [:]

    private var filterStart: Date?
    private var filterEnd: Date?
    private var filterIngredientId: String?
    private var filterBulkSessionId: String?

    // MARK: - Dependencies

    private let auditService: InventoryAuditServiceProtocol
    private let ingredientDataService: IngredientDataServiceProtocol

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    init(
        auditService: InventoryAuditServiceProtocol = InventoryAuditService.shared,
        ingredientDataService: IngredientDataServiceProtocol = DomainIngredientDataService.shared
    ) {
        self.auditService = auditService
        self.ingredientDataService = ingredientDataService
    }

    // MARK: - Filter

    func setFilter(startDate: Date?, endDate: Date?, ingredientId: String?) {
        self.filterStart = startDate
        self.filterEnd = endDate
        self.filterIngredientId = ingredientId
        fetchData()
    }

    func setFilter(bulkSessionId: String?) {
        self.filterBulkSessionId = bulkSessionId
        fetchData()
    }

    // MARK: - Fetch

    func fetchData() {
        isLoading?(true)
        Task {
            do {
                async let ingredients = try await ingredientDataService.fetchIngredients()
                async let adjustments = try await auditService.fetchAdjustments(
                    from: filterStart,
                    to: filterEnd,
                    ingredientId: filterIngredientId,
                    bulkSessionId: filterBulkSessionId
                )

                let (fetchedIngredients, fetchedAdjustments) = try await (ingredients, adjustments)
                let mappedById = Dictionary(
                    uniqueKeysWithValues: fetchedIngredients.map { ($0.id, $0) })

                await MainActor.run {
                    self.ingredientsById = mappedById
                    self.rawAdjustments = fetchedAdjustments
                    self.items = fetchedAdjustments.map { self.makeItem(from: $0) }
                    self.sections = self.makeSections(
                        from: self.items, adjustments: fetchedAdjustments)
                    self.isLoading?(false)
                    self.onDataUpdated?()
                }
            } catch {
                await MainActor.run {
                    self.isLoading?(false)
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Accessor

    func adjustment(at indexPath: IndexPath) -> InventoryAdjustmentModel? {
        guard indexPath.section < sections.count else { return nil }
        let sectionItems = sections[indexPath.section].items
        guard indexPath.row < sectionItems.count else { return nil }
        let id = sectionItems[indexPath.row].id
        return rawAdjustments.first { $0.id == id }
    }

    // MARK: - Private

    private func makeItem(from adjustment: InventoryAdjustmentModel)
        -> InventoryAdjustmentListItemViewModel
    {
        let ingredient = ingredientsById[adjustment.ingredientId]
        let ingredientName = ingredient?.name ?? R.string.global.inventoryUnknownIngredient()
        let unitText = ingredient?.unit.localizedName ?? ""

        let sign: FloatingPointSign = adjustment.quantityDelta >= 0 ? .plus : .minus
        let deltaFormatted = Self.formatDelta(adjustment.quantityDelta, unit: unitText)

        return InventoryAdjustmentListItemViewModel(
            id: adjustment.id,
            dateText: dateFormatter.string(from: adjustment.date),
            ingredientName: ingredientName,
            unitText: unitText,
            deltaText: deltaFormatted,
            deltaSign: sign,
            reasonText: adjustment.reason,
            sourceText: adjustment.source.displayName,
            bulkSessionId: adjustment.bulkSessionId
        )
    }

    private func makeSections(
        from items: [InventoryAdjustmentListItemViewModel],
        adjustments: [InventoryAdjustmentModel]
    ) -> [(date: Date, items: [InventoryAdjustmentListItemViewModel])] {
        var idToDay: [String: Date] = [:]
        for adjustment in adjustments {
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day], from: adjustment.date)
            let day = Calendar.current.date(from: comps) ?? adjustment.date
            idToDay[adjustment.id] = day
        }

        let grouped = Dictionary(grouping: items) { item -> Date in
            idToDay[item.id] ?? Date()
        }

        return
            grouped
            .map { (date: $0.key, items: $0.value) }
            .sorted { lhs, rhs in lhs.date > rhs.date }
    }

    static func formatDelta(_ value: Double, unit: String) -> String {
        let sign = value >= 0 ? "+" : "−"
        let absValue = abs(value)
        let number = String(format: "%.2f", absValue)
        if unit.isEmpty {
            return "\(sign)\(number)"
        }
        return "\(sign)\(number) \(unit)"
    }
}
