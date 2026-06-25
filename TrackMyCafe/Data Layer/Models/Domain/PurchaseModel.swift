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

    init(realmModel: RealmPurchaseModel) {
        self.id = realmModel.id
        self.date = realmModel.date
        self.ingredientId = realmModel.ingredientId
        self.quantity = realmModel.quantity
        self.price = realmModel.price
        self.totalAmount = realmModel.totalAmount ?? (realmModel.quantity * realmModel.price)
        self.paymentAccount = realmModel.paymentAccountRaw.flatMap(PaymentAccount.init(rawValue:))
        self.supplierId = realmModel.supplierId
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
