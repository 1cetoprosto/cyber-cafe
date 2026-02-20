//
//  PurchaseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

struct PurchaseModel: Identifiable, Codable {
    let id: String
    let date: Date
    let ingredientId: String
    let quantity: Double
    let price: Double  // Unit price
    let supplierId: String?

    // Computed property for total cost of this purchase
    var totalCost: Double {
        return quantity * price
    }

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        ingredientId: String,
        quantity: Double,
        price: Double,
        supplierId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.ingredientId = ingredientId
        self.quantity = quantity
        self.price = price
        self.supplierId = supplierId
    }

    init(realmModel: RealmPurchaseModel) {
        self.id = realmModel.id
        self.date = realmModel.date
        self.ingredientId = realmModel.ingredientId
        self.quantity = realmModel.quantity
        self.price = realmModel.price
        self.supplierId = realmModel.supplierId
    }

    init(firebaseModel: FIRPurchaseModel) {
        self.id = firebaseModel.id ?? UUID().uuidString
        self.date = firebaseModel.date
        self.ingredientId = firebaseModel.ingredientId
        self.quantity = firebaseModel.quantity
        self.price = firebaseModel.price
        self.supplierId = firebaseModel.supplierId
    }
}
