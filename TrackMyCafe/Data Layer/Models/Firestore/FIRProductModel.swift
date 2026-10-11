//
//  FIRProductModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 30.04.2022.
//

import FirebaseFirestoreSwift
import Foundation

// Firestore persistence shape for an order line item (`OrderItemModel`).
// Field names are kept stable for backward compatibility with existing data:
//   - `price`    ↔ domain `salePrice`
//   - `amount`   ↔ domain `totalSale` (round-tripped snapshot)
//   - `costSum`  ↔ domain `totalCost` (round-tripped snapshot)

struct FIRProductModel: Codable {
    @DocumentID var id: String?
    var productId: String?
    var orderId: String?
    var date = Date()
    var name: String = ""
    var quantity: Int = 0
    var price: Double = 0.0
    var amount: Double = 0.0
    var costPrice: Double = 0.0
    var costSum: Double = 0.0

    init(dataModel: OrderItemModel) {
        self.id = dataModel.id
        self.productId = dataModel.productId
        self.orderId = dataModel.orderId
        self.date = dataModel.date
        self.name = dataModel.name
        self.quantity = dataModel.quantity
        self.price = dataModel.salePrice
        self.amount = dataModel.totalSale
        self.costPrice = dataModel.costPrice
        self.costSum = dataModel.totalCost
    }
}
