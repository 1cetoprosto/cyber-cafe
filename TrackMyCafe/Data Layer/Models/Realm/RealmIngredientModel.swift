//
//  RealmIngredientModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import RealmSwift

class RealmIngredientModel: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var name: String = ""
    @Persisted var averageCost: Double = 0.0
    @Persisted var stockQuantity: Double = 0.0
    @Persisted var unit: String = ""
    
    convenience init(dataModel: IngredientModel) {
        self.init()
        self.id = dataModel.id
        self.name = dataModel.name
        self.averageCost = dataModel.averageCost
        self.stockQuantity = dataModel.stockQuantity
        self.unit = dataModel.unit.rawValue
    }
}
