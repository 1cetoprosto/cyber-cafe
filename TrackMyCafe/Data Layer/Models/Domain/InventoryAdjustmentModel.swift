//
//  InventoryAdjustmentModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

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
