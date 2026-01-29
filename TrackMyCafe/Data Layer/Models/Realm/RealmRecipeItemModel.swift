//
//  RealmRecipeItemModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import RealmSwift

class RealmRecipeItemModel: Object {
    @Persisted var id: String = ""
    @Persisted var ingredientId: String = ""
    @Persisted var ingredientName: String = ""
    @Persisted var quantity: Double = 0.0
    @Persisted var unit: String = ""
    
    convenience init(dataModel: RecipeItemModel) {
        self.init()
        self.id = dataModel.id
        self.ingredientId = dataModel.ingredientId
        self.ingredientName = dataModel.ingredientName
        self.quantity = dataModel.quantity
        self.unit = dataModel.unit.rawValue
    }
}
