//
//  RealmPurchaseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation
import RealmSwift

class RealmPurchaseModel: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var date: Date = Date()
    @Persisted var ingredientId: String = ""
    @Persisted var quantity: Double = 0.0
    @Persisted var price: Double = 0.0
    @Persisted var supplierId: String? = nil

    convenience init(dataModel: PurchaseModel) {
        self.init()
        self.id = dataModel.id
        self.date = dataModel.date
        self.ingredientId = dataModel.ingredientId
        self.quantity = dataModel.quantity
        self.price = dataModel.price
        self.supplierId = dataModel.supplierId
    }
}
