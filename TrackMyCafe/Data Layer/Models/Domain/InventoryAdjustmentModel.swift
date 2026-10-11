//
//  InventoryAdjustmentModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

// MARK: - InventoryAdjustmentModel
//
// Domain model for stock adjustments (waste, surplus, recounts).
// See `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.4 (InventoryAdjustment).
//
// Target shape (spec): id, date, ingredientId, quantityDelta, reason.
//
// Intentional v1.x deviations from the target spec:
// - `reason` is optional (spec lists it as required) to support bulk recounts
//   where a reason is attached at the session level, not per line.
// - `source` (manual / bulkCount / system) tracks how the adjustment was made.
// - `bulkSessionId` groups adjustments from a single inventory-audit session (v1.1.2).
// - `userId` records who performed the adjustment.

enum InventoryAdjustmentSource: String, CaseIterable, Codable {
    case manual = "manual"
    case bulkCount = "bulkCount"
    case system = "system"

    var displayName: String {
        switch self {
        case .manual:
            return R.string.global.inventoryAdjustmentSourceManual()
        case .bulkCount:
            return R.string.global.inventoryAdjustmentSourceBulkCount()
        case .system:
            return R.string.global.inventoryAdjustmentSourceSystem()
        }
    }
}

struct InventoryAdjustmentModel: Identifiable, Codable {
    let id: String
    let date: Date
    let ingredientId: String
    let quantityDelta: Double
    let reason: String?
    let source: InventoryAdjustmentSource
    let bulkSessionId: String?
    let userId: String?

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        ingredientId: String,
        quantityDelta: Double,
        reason: String? = nil,
        source: InventoryAdjustmentSource = .manual,
        bulkSessionId: String? = nil,
        userId: String? = {
            let session = UserSession.current
            return session.userId
        }()
    ) {
        self.id = id
        self.date = date
        self.ingredientId = ingredientId
        self.quantityDelta = quantityDelta
        self.reason = reason
        self.source = source
        self.bulkSessionId = bulkSessionId
        self.userId = userId
    }
}
