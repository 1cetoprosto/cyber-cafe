//
//  FIRInventoryAdjustmentModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRInventoryAdjustmentModel: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var ingredientId: String
    var quantityDelta: Double
    var reason: String?
    
    init(dataModel: InventoryAdjustmentModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.ingredientId = dataModel.ingredientId
        self.quantityDelta = dataModel.quantityDelta
        self.reason = dataModel.reason
    }
}
