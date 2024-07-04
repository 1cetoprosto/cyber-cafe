//
//  IAPReceiptAdapterProtocol.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 29.06.2024.
//

import Foundation

protocol IAPReceiptAdapterProtocol {
    
    var hasSubscriptionPurchases: Bool { get }
    
    var hasActiveAutorenewSubscription: Bool { get }
    
    
    var lastAutorenewProductId: String? { get }
    
    var lastAutorenewTransactionId: String? { get }
    
    var lastAutorenewOriginTransactionId: String? { get }
    
    
    var purchaseDateForLastAutorenewSubscription: Date? { get }
    
    var expireDateForLastAutorenewSubscription: Date? { get }
    
    func hasPurchaseWithTransactionId(_ transactionId: String) -> Bool
}
