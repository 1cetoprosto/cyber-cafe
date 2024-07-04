//
//  IAPReceiptAdapterLocalValidation.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 29.06.2024.
//

import Foundation
import TPInAppReceipt

class IAPReceiptAdapterLocalValidation: IAPReceiptAdapterProtocol {
    
    private let productIdentifiers: [String]
    private let receipt: InAppReceipt
    
    init(_ receipt: InAppReceipt, productIdentifiers: [String] = SubscriptionType.allProducts) {
        self.receipt = receipt
        self.productIdentifiers = productIdentifiers
    }
    
    private var lastSubscriptionPurchase: InAppPurchase? {
        return receipt.autoRenewablePurchases
            .filter { $0.subscriptionExpirationDate != nil }
            .sorted(by: { $0.subscriptionExpirationDate! < $1.subscriptionExpirationDate! })
            .last
    }
    
    var hasSubscriptionPurchases: Bool {
        return productIdentifiers.contains { receipt.containsPurchase(ofProductIdentifier: $0) }
    }
    
    var hasActiveAutorenewSubscription: Bool {
        return productIdentifiers.contains { receipt.hasActiveAutoRenewableSubscription(ofProductIdentifier: $0, forDate: Date.subCheckDate()) }
    }
    
    var lastAutorenewProductId: String? {
        return lastSubscriptionPurchase?.productIdentifier
    }
    
    var lastAutorenewTransactionId: String? {
        return lastSubscriptionPurchase?.transactionIdentifier
    }
    
    var lastAutorenewOriginTransactionId: String? {
        return lastSubscriptionPurchase?.originalTransactionIdentifier
    }
    
    var purchaseDateForLastAutorenewSubscription: Date? {
        return lastSubscriptionPurchase?.purchaseDate
    }
    
    var expireDateForLastAutorenewSubscription: Date? {
        return lastSubscriptionPurchase?.subscriptionExpirationDate
    }
    
    func hasPurchaseWithTransactionId(_ transactionId: String) -> Bool {
        return receipt.autoRenewablePurchases.contains { $0.transactionIdentifier == transactionId || $0.originalTransactionIdentifier == transactionId }
    }
}

