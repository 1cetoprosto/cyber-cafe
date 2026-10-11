//
//  DomainInventoryAdjustmentDataService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import Foundation

enum DomainInventoryAdjustmentError: Error {
    case saveFailed
    case fetchFailed
}

protocol InventoryAdjustmentDataServiceProtocol {
    func fetchAdjustments(
        from startDate: Date?,
        to endDate: Date?,
        ingredientId: String?,
        bulkSessionId: String?
    ) async throws -> [InventoryAdjustmentModel]

    func saveAdjustment(_ adjustment: InventoryAdjustmentModel) async throws
}

final class DomainInventoryAdjustmentDataService: InventoryAdjustmentDataServiceProtocol {
    static let shared = DomainInventoryAdjustmentDataService()

    private init() {}

    @MainActor
    func fetchAdjustments(
        from startDate: Date?,
        to endDate: Date?,
        ingredientId: String?,
        bulkSessionId: String?
    ) async throws -> [InventoryAdjustmentModel] {
        await DomainDatabaseService.shared.fetchInventoryAdjustments(
            from: startDate,
            to: endDate,
            ingredientId: ingredientId,
            bulkSessionId: bulkSessionId
        )
    }

    @MainActor
    func saveAdjustment(_ adjustment: InventoryAdjustmentModel) async throws {
        let id = await DomainDatabaseService.shared.saveInventoryAdjustment(model: adjustment)
        guard id != nil else {
            throw DomainInventoryAdjustmentError.saveFailed
        }
    }
}
