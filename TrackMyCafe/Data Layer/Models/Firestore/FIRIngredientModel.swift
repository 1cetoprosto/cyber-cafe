//
//  FIRIngredientModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRIngredientModel: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var averageCost: Double
    var stockQuantity: Double
    var unit: String
    var minStockThreshold: Double?

    init(dataModel: IngredientModel) {
        self.id = dataModel.id
        self.name = dataModel.name
        self.averageCost = dataModel.averageCost
        self.stockQuantity = dataModel.stockQuantity
        self.unit = dataModel.unit.rawValue
        self.minStockThreshold = dataModel.minStockThreshold
    }
}
