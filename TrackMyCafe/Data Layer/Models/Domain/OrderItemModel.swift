//
//  OrderItemModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

// MARK: - OrderItemModel
//
// COGS snapshot for a single line of an order.
// See `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.3 (Sale / Order).
//
// Target shape (spec): productId, quantity, salePrice, costPrice.
//
// This is the canonical snapshot model used by `CostingService`,
// `InventoryService` and aggregation/reporting. It is intentionally separate
// from `ProductOfOrderModel` (the display/persistence line model) — see that
// file's header for the role split.

struct OrderItemModel: Identifiable, Codable {
    let id: String
    let productId: String
    let quantity: Int
    let salePrice: Double  // Price at the moment of sale
    let costPrice: Double  // COGS at the moment of sale

    var totalSale: Double { salePrice * Double(quantity) }
    var totalCost: Double { costPrice * Double(quantity) }

    init(
        id: String = UUID().uuidString,
        productId: String,
        quantity: Int,
        salePrice: Double,
        costPrice: Double = 0.0  // Can be calculated later or passed during creation
    ) {
        self.id = id
        self.productId = productId
        self.quantity = quantity
        self.salePrice = salePrice
        self.costPrice = costPrice
    }

    init(product: ProductOfOrderModel) {
        self.id = product.id
        self.productId = product.productId
        self.quantity = product.quantity
        self.salePrice = product.price
        self.costPrice = product.costPrice
    }
}
