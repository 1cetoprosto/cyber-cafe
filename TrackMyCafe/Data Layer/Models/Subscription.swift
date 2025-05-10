//
//  Subscription.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import Foundation

class Subscription: CustomStringConvertible {
    
    enum Provider: String {
        case ios = "ios"
        case android = "android"
        case none = "none"
    }
    
    var premiumPlan: Bool
    var provider: Provider
    var paymentDate: Date?
    var nextPaymentDate: Date?
    
    // only iOS properties
    var productId: String?
    
    var transactionId: String?
    var originTransactionId: String?
    
    var hasIOSSub: Bool {
        return provider == .ios && nextPaymentDate != nil && (transactionId ?? originTransactionId) != nil
    }
    
    var isActive: Bool {
        guard let expireDate = nextPaymentDate else { return false }
        return expireDate > Date.subCheckDate()
    }
    
    init() {
        premiumPlan = false
        provider = .none
        paymentDate = nil
        nextPaymentDate = nil
    }
    
    init(_ data: [String: Any]) {
        self.premiumPlan = (data["premiumPlan"] as? Bool) ?? false
        if let providerId = data["providerId"] as? String {
            self.provider = Provider(rawValue: providerId) ?? .none
        } else {
            self.provider = .none
        }
        
        if let dateInterval = data["paymentDate"] as? Double {
            self.paymentDate = Date(timeIntervalSince1970: dateInterval)
        }
        
        if let dateInterval = data["nextPaymentDate"] as? Double {
            self.nextPaymentDate = Date(timeIntervalSince1970: dateInterval)
        }
        
        self.productId = data["iosProductId"] as? String
        self.transactionId = data["iosTransactionId"] as? String
        self.originTransactionId = data["iosOriginTransactionId"] as? String
    }
}
