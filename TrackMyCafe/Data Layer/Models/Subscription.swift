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

    var proPlan: Bool
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

    // Check if user is in trial period
    var isInTrial: Bool {
        // If we have an active subscription that hasn't started charging yet, it's likely a trial
        return provider == .ios && isActive && (transactionId ?? originTransactionId) != nil
    }

    var isActive: Bool {
        guard let expireDate = nextPaymentDate else { return false }
        // For trial periods, we should consider them active even if they haven't started charging yet
        // The expireDate for trials represents when the trial ends, not when billing starts
        return expireDate > Date.subCheckDate()
    }

    init() {
        proPlan = false
        provider = .none
        paymentDate = nil
        nextPaymentDate = nil
    }

    // Initialize with default trial period if needed
    static func withTrialPeriod(expireDate: Date) -> Subscription {
        let subscription = Subscription()
        subscription.provider = .ios
        subscription.nextPaymentDate = expireDate
        // For trial periods, we consider the user as having a premium plan
        subscription.proPlan = true
        return subscription
    }

    init(_ data: [String: Any]) {
        self.proPlan = (data["premiumPlan"] as? Bool) ?? false // Keep "premiumPlan" key for data compatibility
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

        // If we have an active subscription (including trial) but proPlan is false, update it
        if !self.proPlan && self.isActive && self.provider == .ios {
            self.proPlan = true
        }

        self.productId = data["iosProductId"] as? String
        self.transactionId = data["iosTransactionId"] as? String
        self.originTransactionId = data["iosOriginTransactionId"] as? String
    }
}
