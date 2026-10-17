//
//  OrderModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

// MARK: - OrderModel
//
// Domain model for a sale / order (чек).
// See `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.3 (Sale / Order).
//
// Target shape (spec): id, date, items: [OrderItemModel], totalAmount, totalCost.
//
// Intentional v1.x deviations from the target spec:
// - `sum` is used instead of `totalAmount` (legacy naming; equals Sales total).
//   `totalAmount` is provided as a computed alias for spec alignment.
// - `cash` / `card` split the payment for cash/card reporting (v1.1.x).
// - `type` carries the receipt/order type.
// - `inventoryTracking` snapshots the Track-Ingredients setting at sale time.
// - Order line items are NOT embedded here; they are stored as separate
//   `OrderItemModel` documents (linked by `orderId` in the `productOfOrders`
//   Firestore collection). `fetchOrderItems(withOrderId:)` retrieves them.
// - `totalCost` is the frozen COGS snapshot at the moment of sale.
// - Firebase/dictionary conversion initializers support Firestore round-trip.

struct OrderModel {
    var id: String
    var date: Date
    var type: String
    var sum: Double
    var cash: Double
    var card: Double
    var totalCost: Double
    var inventoryTracking: Bool
    var note: String?
    /// Firebase ref of the employee who created the order (employeeRef).
    /// `nil` for legacy orders created before v1.2 — treated as owner-created.
    var createdBy: String?

    /// Spec-aligned alias for the sales total (`sum`).
    var totalAmount: Double { sum }

    init(
        id: String,
        date: Date,
        type: String,
        sum: Double,
        cash: Double,
        card: Double,
        totalCost: Double = 0.0,
        inventoryTracking: Bool = false,
        note: String? = nil,
        createdBy: String? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.sum = sum
        self.cash = cash
        self.card = card
        self.totalCost = totalCost
        self.inventoryTracking = inventoryTracking
        self.note = note
        self.createdBy = createdBy
    }

    init(firebaseModel: FIROrderModel) {
        self.id = firebaseModel.id ?? ""
        self.date = firebaseModel.date
        self.type = firebaseModel.type
        self.sum = firebaseModel.sum
        self.cash = firebaseModel.cash
        self.card = firebaseModel.card
        self.totalCost = firebaseModel.totalCost ?? 0.0
        self.inventoryTracking = firebaseModel.inventoryTracking ?? false
        self.note = firebaseModel.note
        self.createdBy = firebaseModel.createdBy
    }

    init?(_ data: [String: Any]) {
        guard let id = data["id"] as? String else { return nil }
        self.id = id
        self.date = Date(timeIntervalSince1970: data["date"] as? Double ?? 0)
        self.type = (data["type"] as? String)?.nilIfEmpty ?? DefaultValues.defaultOrderType
        self.sum = data["sum"] as? Double ?? 0.0
        self.cash = data["cash"] as? Double ?? 0.0
        self.card = data["card"] as? Double ?? 0.0
        self.totalCost = data["totalCost"] as? Double ?? 0.0
        self.inventoryTracking = data["inventoryTracking"] as? Bool ?? false
        self.note = (data["note"] as? String)?.nilIfEmpty
        self.createdBy = (data["createdBy"] as? String)?.nilIfEmpty
    }
}
