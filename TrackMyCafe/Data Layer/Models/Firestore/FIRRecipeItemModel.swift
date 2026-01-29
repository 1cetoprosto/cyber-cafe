//
//  FIRRecipeItemModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation

struct FIRRecipeItemModel: Codable {
    var id: String
    var ingredientId: String
    var ingredientName: String
    var quantity: Double
    var unit: String
    
    init(dataModel: RecipeItemModel) {
        self.id = dataModel.id
        self.ingredientId = dataModel.ingredientId
        self.ingredientName = dataModel.ingredientName
        self.quantity = dataModel.quantity
        self.unit = dataModel.unit.rawValue
    }
}
