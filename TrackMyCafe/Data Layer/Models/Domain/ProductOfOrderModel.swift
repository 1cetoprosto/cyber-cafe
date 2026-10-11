//
//  ProductModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

// MARK: - ProductOfOrderModel
//
// Display + persistence model for a single line of an order (product in a check).
// Related to `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.3 (Sale / Order).
//
// Role split (NOT a duplicate of `OrderItemModel`):
// - `ProductOfOrderModel` is the UI/persistence line: it carries denormalized
//   `name`, `orderId`, `date`, `sum`, `costSum` so the order-details product
//   list can render without extra lookups, and so each line can be saved to
//   Firestore independently.
// - `OrderItemModel` is the COGS snapshot: `productId`, `quantity`, `salePrice`,
//   `costPrice`. It is what `CostingService` / `InventoryService` consume.
//
// Bridge: `ProductOfOrderModel.orderItemSnapshot` → `OrderItemModel`
//         and `OrderItemModel.init(product:)` ← `ProductOfOrderModel`.
//
// Firebase conversion initializers support Firestore round-trip.

struct ProductOfOrderModel: Equatable {
    var id: String
    var productId: String
    var orderId: String
    var date: Date
    var name: String
    var quantity: Int
    var price: Double
    var sum: Double
    var costPrice: Double
    var costSum: Double

    init(
        id: String, productId: String = "", orderId: String, date: Date, name: String,
        quantity: Int, price: Double, sum: Double, costPrice: Double = 0.0, costSum: Double = 0.0
    ) {
        self.id = id
        self.productId = productId
        self.orderId = orderId
        self.date = date
        self.name = name
        self.quantity = quantity
        self.price = price
        self.sum = sum
        self.costPrice = costPrice
        self.costSum = costSum
    }

    init(firebaseModel: FIRProductModel) {
        self.id = firebaseModel.id ?? ""
        self.productId = firebaseModel.productId ?? ""
        self.orderId = firebaseModel.orderId ?? ""
        self.date = firebaseModel.date
        self.name = firebaseModel.name
        self.quantity = firebaseModel.quantity
        self.price = firebaseModel.price
        self.sum = firebaseModel.amount
        self.costPrice = firebaseModel.costPrice
        self.costSum = firebaseModel.costSum
    }

    var orderItemSnapshot: OrderItemModel {
        OrderItemModel(product: self)
    }

    var hasCostSnapshot: Bool {
        abs(costPrice) >= 0.000_1 || abs(costSum) >= 0.000_1
    }

    mutating func apply(snapshot: OrderItemModel) {
        productId = snapshot.productId
        quantity = snapshot.quantity
        price = snapshot.salePrice
        sum = snapshot.totalSale
        costPrice = snapshot.costPrice
        costSum = snapshot.totalCost
    }
}
