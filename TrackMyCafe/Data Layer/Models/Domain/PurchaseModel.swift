//
//  PurchaseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

// MARK: - PurchaseModel
//
// Domain model for ingredient purchases (stock replenishment).
// See `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.1 (Purchase).
//
// Target shape (spec): id, date, ingredientId, quantity, price, supplierId?
//   with computed `totalCost = quantity * price`.
//
// Intentional v1.x deviations from the target spec:
// - `totalAmount` is stored (not only computed) so Firestore records keep the
//   exact total captured at save time (round-trip safety). `totalCost` aliases it.
// - `paymentAccount` is added to support cash/card split reporting (v1.1.x).
// - Firebase conversion initializers support Firestore round-trip.

struct PurchaseModel: Identifiable, Codable {
    let id: String
    let date: Date
    let ingredientId: String
    let quantity: Double
    let price: Double  // Unit price
    let totalAmount: Double
    let paymentAccount: PaymentAccount?
    let supplierId: String?

    // Temporary compatibility accessor for existing finance/inventory code.
    var totalCost: Double {
        return totalAmount
    }

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        ingredientId: String,
        quantity: Double,
        price: Double,
        totalAmount: Double? = nil,
        paymentAccount: PaymentAccount? = nil,
        supplierId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.ingredientId = ingredientId
        self.quantity = quantity
        self.price = price
        self.totalAmount = totalAmount ?? (quantity * price)
        self.paymentAccount = paymentAccount
        self.supplierId = supplierId
    }

    init(firebaseModel: FIRPurchaseModel) {
        self.id = firebaseModel.id ?? UUID().uuidString
        self.date = firebaseModel.date
        self.ingredientId = firebaseModel.ingredientId
        self.quantity = firebaseModel.quantity
        self.price = firebaseModel.price
        self.totalAmount =
            firebaseModel.totalAmount ?? (firebaseModel.quantity * firebaseModel.price)
        self.paymentAccount = firebaseModel.paymentAccount
        self.supplierId = firebaseModel.supplierId
    }
}
