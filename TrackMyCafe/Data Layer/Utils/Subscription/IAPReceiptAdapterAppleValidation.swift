//
//  IAPReceiptAdapterAppleValidation.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 29.06.2024.
//

import Foundation
import SwiftyStoreKit

class IAPReceiptAdapterAppleValidation: IAPReceiptAdapterProtocol {
    
    private let productIdentifiers: [String]
    private let receipt: ReceiptInfo
    
    init(_ receipt: ReceiptInfo, productIdentifiers: [String] = SubscriptionType.allProducts) {
        self.receipt = receipt
        self.productIdentifiers = productIdentifiers
    }
    
    private var lastSubscriptionPurchase: ReceiptItem? {
        let result = SwiftyStoreKit.verifySubscriptions(productIds: Set(productIdentifiers), inReceipt: receipt)
        switch result {
            case .purchased(_ , let items), .expired(_, let items):
                return items
                    .filter { $0.subscriptionExpirationDate != nil }
                    .sorted(by: { $0.subscriptionExpirationDate! < $1.subscriptionExpirationDate! })
                    .last
            case .notPurchased:
                return nil
        }
    }
    
    var hasSubscriptionPurchases: Bool {
        return (SwiftyStoreKit.getDistinctPurchaseIds(inReceipt: receipt)?.count ?? 0) > 0
    }
    
    var hasActiveAutorenewSubscription: Bool {
        let result = SwiftyStoreKit.verifySubscriptions(productIds: Set(productIdentifiers), inReceipt: receipt)
        switch result {
            case .purchased: return true
            case .expired, .notPurchased: return false
        }
    }
    
    
    var lastAutorenewProductId: String? {
        return lastSubscriptionPurchase?.productId
    }
    
    var lastAutorenewTransactionId: String? {
        return lastSubscriptionPurchase?.transactionId
    }
    
    var lastAutorenewOriginTransactionId: String? {
        return lastSubscriptionPurchase?.originalTransactionId
    }
    
    
    var purchaseDateForLastAutorenewSubscription: Date? {
        return lastSubscriptionPurchase?.purchaseDate
    }
    
    var expireDateForLastAutorenewSubscription: Date? {
        return lastSubscriptionPurchase?.subscriptionExpirationDate
    }
    
    func hasPurchaseWithTransactionId(_ transactionId: String) -> Bool {
        let result = SwiftyStoreKit.verifySubscriptions(productIds: Set(productIdentifiers), inReceipt: receipt)
        switch result {
            case .expired(_, let items), .purchased(_, let items):
                return items.contains { $0.transactionId == transactionId || $0.originalTransactionId == transactionId }
            case .notPurchased:
                return false
        }
    }
}

