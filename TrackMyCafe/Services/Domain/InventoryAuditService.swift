//
//  InventoryAuditService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import Foundation
import os.log

protocol InventoryAuditServiceProtocol {
    func fetchAdjustments(
        from startDate: Date?,
        to endDate: Date?,
        ingredientId: String?,
        bulkSessionId: String?
    ) async throws -> [InventoryAdjustmentModel]

    func createAdjustment(
        ingredientId: String,
        quantityDelta: Double,
        reason: String,
        source: InventoryAdjustmentSource,
        bulkSessionId: String?
    ) async throws

    func startBulkSession(includeAllIngredients: Bool) async throws -> InventoryBulkSession

    func commitBulkSession(
        _ session: InventoryBulkSession,
        reason: String
    ) async throws -> [InventoryAdjustmentModel]
}

struct InventoryBulkSessionItem: Identifiable {
    let id: String
    let ingredient: IngredientModel
    var expectedQuantity: Double
    var countedQuantity: Double?
}

struct InventoryBulkSession: Identifiable {
    let id: String
    let startedAt: Date
    var items: [InventoryBulkSessionItem]

    init(
        id: String = UUID().uuidString, startedAt: Date = Date(), items: [InventoryBulkSessionItem]
    ) {
        self.id = id
        self.startedAt = startedAt
        self.items = items
    }
}

final class InventoryAuditService: InventoryAuditServiceProtocol {
    static let shared = InventoryAuditService()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TrackMyCafe",
        category: "InventoryAuditService"
    )

    private let adjustmentDataService: InventoryAdjustmentDataServiceProtocol
    private let inventoryService: InventoryServiceProtocol
    private let ingredientDataService: IngredientDataServiceProtocol

    init(
        adjustmentDataService: InventoryAdjustmentDataServiceProtocol =
            DomainInventoryAdjustmentDataService.shared,
        inventoryService: InventoryServiceProtocol = InventoryService.shared,
        ingredientDataService: IngredientDataServiceProtocol = DomainIngredientDataService.shared
    ) {
        self.adjustmentDataService = adjustmentDataService
        self.inventoryService = inventoryService
        self.ingredientDataService = ingredientDataService
    }

    // MARK: - Query

    func fetchAdjustments(
        from startDate: Date?,
        to endDate: Date?,
        ingredientId: String?,
        bulkSessionId: String?
    ) async throws -> [InventoryAdjustmentModel] {
        try await adjustmentDataService.fetchAdjustments(
            from: startDate,
            to: endDate,
            ingredientId: ingredientId,
            bulkSessionId: bulkSessionId
        )
    }

    // MARK: - Single adjustment (legacy path, goes through InventoryService for stock+adjustment atomicity)

    func createAdjustment(
        ingredientId: String,
        quantityDelta: Double,
        reason: String,
        source: InventoryAdjustmentSource,
        bulkSessionId: String?
    ) async throws {
        let adjustment = InventoryAdjustmentModel(
            ingredientId: ingredientId,
            quantityDelta: quantityDelta,
            reason: reason,
            source: source,
            bulkSessionId: bulkSessionId
        )

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            inventoryService.processStockAdjustment(adjustment: adjustment) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Start bulk session

    func startBulkSession(includeAllIngredients: Bool = true) async throws -> InventoryBulkSession {
        let ingredients = try await ingredientDataService.fetchIngredients().sorted(by: {
            $0.name < $1.name
        })
        let items = ingredients.map { ingredient -> InventoryBulkSessionItem in
            InventoryBulkSessionItem(
                id: UUID().uuidString,
                ingredient: ingredient,
                expectedQuantity: ingredient.stockQuantity,
                countedQuantity: nil
            )
        }
        return InventoryBulkSession(items: items)
    }

    // MARK: - Commit bulk session

    func commitBulkSession(
        _ session: InventoryBulkSession,
        reason: String
    ) async throws -> [InventoryAdjustmentModel] {
        let sessionReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sessionReason.isEmpty else {
            throw NSError(
                domain: "InventoryAuditService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        R.string.global.fieldRequired(R.string.global.inventoryBulkSessionNote())
                ]
            )
        }
        let adjustments: [InventoryAdjustmentModel] = session.items.compactMap { item in
            guard let counted = item.countedQuantity else { return nil }
            let delta = counted - item.expectedQuantity
            guard delta != 0 else { return nil }
            return InventoryAdjustmentModel(
                date: Date(),
                ingredientId: item.ingredient.id,
                quantityDelta: delta,
                reason: sessionReason,
                source: .bulkCount,
                bulkSessionId: session.id
            )
        }

        guard !adjustments.isEmpty else {
            logger.info("Bulk session committed with no deltas; nothing to save.")
            return []
        }

        for adjustment in adjustments {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Error>) in
                inventoryService.processStockAdjustment(adjustment: adjustment) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        return adjustments
    }
}
