//
//  FIRPurchaseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import FirebaseFirestoreSwift
import Foundation

struct FIRPurchaseModel: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var ingredientId: String
    var quantity: Double
    var price: Double
    var totalAmount: Double?
    var paymentAccount: PaymentAccount?
    var supplierId: String?

    init(dataModel: PurchaseModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.ingredientId = dataModel.ingredientId
        self.quantity = dataModel.quantity
        self.price = dataModel.price
        self.totalAmount = dataModel.totalAmount
        self.paymentAccount = dataModel.paymentAccount
        self.supplierId = dataModel.supplierId
    }
}
