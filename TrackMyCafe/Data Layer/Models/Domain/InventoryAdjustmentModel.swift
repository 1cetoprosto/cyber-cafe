//
//  InventoryAdjustmentModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

struct InventoryAdjustmentModel: Identifiable, Codable {
    let id: String
    let date: Date
    let ingredientId: String
    let quantityDelta: Double // Positive to add, negative to remove
    let reason: String?
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        ingredientId: String,
        quantityDelta: Double,
        reason: String? = nil
    ) {
        self.id = id
        self.date = date
        self.ingredientId = ingredientId
        self.quantityDelta = quantityDelta
        self.reason = reason
    }
}
