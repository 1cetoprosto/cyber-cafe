//
//  FIRIngredientModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRIngredientModel: Codable {
    @DocumentID var id: String?
    var name: String
    var averageCost: Double
    var stockQuantity: Double
    var unit: String
    
    init(dataModel: IngredientModel) {
        self.id = dataModel.id
        self.name = dataModel.name
        self.averageCost = dataModel.averageCost
        self.stockQuantity = dataModel.stockQuantity
        self.unit = dataModel.unit.rawValue
    }
}
