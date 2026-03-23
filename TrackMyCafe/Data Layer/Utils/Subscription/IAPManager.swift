//
//  IAPManager.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 29.06.2024.
//

import Foundation
import SwiftyStoreKit
import StoreKit
import TPInAppReceipt

private var kSharedSecret: String {
    #if DEV
    return "43d46471b376404bb921b2c73536cfb1"
    #elseif BETA
    return "ed794102f4c748648257f9120e6b4e8c"
    #elseif PROD
    return "1011cc50a065475cad461ba3748fba71"
    #else
    return ""
    #endif
}

extension Date {

    static func subCheckDate() -> Date {
        return Date()
//        let nowUTC = Date()
//        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: nowUTC))
//        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: nowUTC) else {return Date()}
//
//        return localDate
    }
}

class IAPManager: NSObject, Loggable {

    static let shared = IAPManager()

    // MARK: - Public properties
    var currentSubscription: SubscriptionType {
        guard let subscription = RequestManager.shared.subscription else { return .none }
        if subscription.proPlan { return .proMonthly }
        guard subscription.isActive, let productId = subscription.productId else { return .none }
        return SubscriptionType(rawValue: productId) ?? .none
    }

    @AppDefaults<Date>(key: UserDefaultsKeys.subscriptionNextPaymentDate)
    var nextPaymentDate: Date?

    @AppDefaults<Bool>(key: UserDefaultsKeys.subscriptionIsProPlan)
    var isProPlan: Bool?

    // MARK: - Public methods
    func updateInfo(_ subscription: Subscription) {
        let isActive = subscription.isActive
        let hasActiveSubscription = subscription.hasIOSSub
        logger.debug("IAPManager: Updating subscription info from RequestManager. Pro: \(subscription.proPlan), Active by Date: \(isActive), Has iOS Sub: \(hasActiveSubscription), Next Payment: \(String(describing: subscription.nextPaymentDate))")
        nextPaymentDate = subscription.nextPaymentDate
        let newProStatus = subscription.proPlan || (hasActiveSubscription && isActive)
        if newProStatus {
            isProPlan = true
        } else if isProPlan == true {
            logger.debug("IAPManager: Firebase says not pro, but local state is pro. Keeping local state until receipt verification.")
        } else {
            isProPlan = false
        }
    }

    func getProducts(_ completion: (([SKProduct]?) -> Void)?) {
        guard SwiftyStoreKit.canMakePayments else {
            completion?(nil);
            return
        }
        SwiftyStoreKit.retrieveProductsInfo(SubscriptionType.allProductsSet) { (results) in
            let products = Array(results.retrievedProducts).sorted(by: { $0.price.decimalValue < $1.price.decimalValue })
            completion?(products)
        }
    }

    func purchaseProduct(_ product: SKProduct, completion: ((Bool, String?) -> Void)? = nil) {
        guard SwiftyStoreKit.canMakePayments else {
            completion?(false, nil);
            return
        }
        SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { (result) in
            switch result {
            case .success:
                // Verify subscription even if atomically is true, just to get the receipt
                self.verifySubscription { receipt in
                    if let receipt = receipt {
                        self.updateSubscriptionInfo(receipt)
                        // No need to finish transaction manually if atomically is true,
                        // but if we want to be safe with verification flow:
                        // SwiftyStoreKit automatically finishes it if atomically: true
                    }
                    completion?(receipt != nil, nil)
                }
            case .error(let error):
                self.logger.error("\(error)")
                completion?(false, error.localizedDescription)
            case .deferred(purchase: let purchase):
                self.logger.info("\(purchase)")
            }
        }
    }

    // MARK: - Debug
    func debugResetSubscription() {
        logger.debug("DEBUG: Resetting subscription status")
        isProPlan = false
        nextPaymentDate = nil
    }

    func restorePurchases(_ completion: (() -> Void)? = nil) {
        guard SwiftyStoreKit.canMakePayments else {
            completion?()
            return
        }

        SwiftyStoreKit.restorePurchases { _ in
            completion?()
        }
    }

    func completeTransactions() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    self.logger.notice("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break // do nothing
                }
            }
        }
    }

    // MARK: - Debug Mock
    struct MockIAPReceiptAdapter: IAPReceiptAdapterProtocol {
        let productId: String
        let transactionId: String

        var lastAutorenewProductId: String? { productId }
        var lastAutorenewTransactionId: String? { transactionId }
        var lastAutorenewOriginTransactionId: String? { transactionId }
        var purchaseDateForLastAutorenewSubscription: Date? { Date() }
        var expireDateForLastAutorenewSubscription: Date? {
            // Default to 14 days trial + 1 month for safety or whatever
            Calendar.current.date(byAdding: .day, value: 30, to: Date())
        }
        var hasSubscriptionPurchases: Bool { true }
        var originalPurchaseDate: Date? { Date() }

        var hasActiveAutorenewSubscription: Bool { true }

        func hasPurchaseWithTransactionId(_ transactionId: String) -> Bool {
            return transactionId == self.transactionId
        }
    }

    func verifySubscription(_ completion: ((IAPReceiptAdapterProtocol?) -> Void)? = nil) {

        // Debug: Try local validation first to see if receipt exists
        if let receiptUrl = Bundle.main.appStoreReceiptURL,
           let _ = try? Data(contentsOf: receiptUrl) {
            self.logger.debug("Receipt exists at: \(receiptUrl)")
        } else {
            self.logger.error("Receipt NOT found locally.")
        }

        // Special handling for Xcode StoreKit Testing (local environment)
        // If we are running in DEBUG and using StoreKit Config, the receipt is signed by a local certificate,
        // which fails remote validation on Apple's servers (both Production and Sandbox) with 21002.
#if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
            ProcessInfo.processInfo.arguments.contains("-com.apple.CoreData.SQLDebug") { // Just a heuristic, better to check certificate
            // Fallback to local validation for Xcode testing
            SwiftyStoreKit.fetchReceipt(forceRefresh: false) { (result) in
                switch result {
                case .success(_):
                    // In local testing, we might need to trust the local certificate or just assume success if data exists
                    // Since we can't easily parse the receipt path easily, we'll try to parse it
                    // Or just mocking success for development flow if we are sure it's Xcode environment

                    // For now, let's try the remote validation first, and if it fails with 21002 in DEBUG,
                    // we assume it's a local StoreKit receipt and proceed manually.
                    break
                case .error:
                    break
                }
            }
        }
#endif

        // Use Apple Validator for production/sandbox (handles switching automatically if needed in logic below)
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: kSharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator, forceRefresh: false) { (result) in
            switch result {
            case .success(let receipt):
                self.logger.debug("Verify success (Production)")
                let receiptAdapter = IAPReceiptAdapterAppleValidation(receipt)
                self.isProPlan = receiptAdapter.hasActiveAutorenewSubscription
                self.updateSubscriptionInfo(receiptAdapter)
                completion?(receiptAdapter)
            case .error(let error):
                self.logger.error("Verify receipt failed (Production): \(error)")

                // Fallback to Sandbox if Production fails
                // 21007: Receipt is from TestFlight/Sandbox but sent to Production
                // 21002: Receipt data is malformed (often happens in Simulator/TestFlight environments when mixed)
                let errorCode = (error as NSError).code
                self.logger.debug("Error code: \(errorCode)")

                // In DEBUG mode with Xcode StoreKit Config, remote validation ALWAYS fails with 21002.
                // We should treat this as a "Success" for local development if we can confirm the purchase happened.
#if DEBUG
                // Check for 21002 in multiple ways:
                // 1. Direct error code
                // 2. SwiftyStoreKit ReceiptError enum match
                // 3. String contains "21002" (last resort)
                var isMalformedData = errorCode == 21002
                if !isMalformedData {
                    if case .receiptInvalid(let receipt, _) = error,
                       let status = receipt["status"] as? Int, status == 21002 {
                        isMalformedData = true
                    }
                }
                if !isMalformedData {
                    isMalformedData = "\(error)".contains("21002")
                }

                if isMalformedData {
                    self.logger.error("Received 21002 in DEBUG. Assuming Xcode StoreKit local receipt. Bypassing remote validation.")
                    // We need to return a dummy adapter or fetch local receipt info
                    // Since we can't easily parse local receipt without a complex parser,
                    // we will try to fetch the receipt locally and assume it's valid for now.
                    SwiftyStoreKit.fetchReceipt(forceRefresh: false) { fetchResult in
                        switch fetchResult {
                        case .success(_):
                            // Try to verify locally if possible, or just return success
                            // Using a mock adapter or local adapter if certificate is available
                            // For this fix, we will try to use the Local Validator if available, otherwise mock it.

                            // Attempting Local Validation
                            do {
                                self.logger.debug("Trying InAppReceipt.localReceipt()...")
                                // Note: InAppReceipt.localReceipt() requires the receipt to be signed correctly
                                // and sometimes fails if the root certificate is not found or mismatch.
                                let receipt = try InAppReceipt.localReceipt()
                                self.logger.debug("Local receipt parsed successfully!")
                                let receiptAdapter = IAPReceiptAdapterLocalValidation(receipt)
                                // Update subscription status immediately
                                self.updateSubscriptionInfo(receiptAdapter)
                                completion?(receiptAdapter)
                            } catch {
                                self.logger.error("Local validation failed with error: \(error)")

                                // Very last resort for Xcode StoreKit Config:
                                // If we can't parse the receipt but we know we bought it (because we are here),
                                // we can try to fetch the active transactions directly from SwiftyStoreKit
                                // This is not "validation" per se, but verification of entitlement.
                                self.logger.debug("Attempting to verify entitlement via active transactions...")

                                // Use SwiftyStoreKit to find the transaction for the product we likely purchased
                                // Or just iterate over all restored transactions?
                                // We can't access payment queue easily here synchronously.

                                // Fallback: Just assume the default monthly product was purchased in DEBUG.
                                // This is a "Developer Bypass" to allow testing the app flow.
                                // Replace "com.example.monthly" with your actual Product ID if possible, or make it dynamic.
                                // Ideally, we should fetch the product ID from somewhere, but verifySubscription is generic.

                                // Let's assume the first available product ID from our known list, or hardcode one for testing.
                                let mockProductId = SubscriptionType.proMonthly.rawValue // "pro.monthly" or whatever your ID is
                                let mockTransactionId = "debug_transaction_\(Int(Date().timeIntervalSince1970))"

                                self.logger.error("Using MOCK Receipt Adapter for DEBUG mode. Product: \(mockProductId)")
                                let mockAdapter = MockIAPReceiptAdapter(productId: mockProductId, transactionId: mockTransactionId)
                                // Update subscription status immediately
                                self.updateSubscriptionInfo(mockAdapter)
                                completion?(mockAdapter)
                            }
                        case .error(let err):
                            self.logger.error("Fetch receipt failed: \(err)")
                            completion?(nil)
                        }
                    }
                    return
                }
#endif

                if errorCode == 21007 || errorCode == 21002 {
                    self.logger.debug("Falling back to Sandbox verification (Error code: \(errorCode))...")
                    let sandboxValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: kSharedSecret)
                    SwiftyStoreKit.verifyReceipt(using: sandboxValidator, forceRefresh: false) { (sandboxResult) in
                        self.logger.debug("Sandbox verification result received")
                        switch sandboxResult {
                        case .success(let receipt):
                            self.logger.debug("Verify success (Sandbox)")
                            let receiptAdapter = IAPReceiptAdapterAppleValidation(receipt)
                            // Update subscription status immediately
                            self.updateSubscriptionInfo(receiptAdapter)
                            completion?(receiptAdapter)
                        case .error(let sandboxError):
                            self.logger.error("Sandbox verify failed: \(sandboxError)")
                            completion?(nil)
                        }
                    }
                } else {
                    completion?(nil)
                }
            }
        }
    }

    func updateSubscriptionInfo(_ receipt: IAPReceiptAdapterProtocol) {
        self.logger.debug("Updating subscription info with receipt...")

        // Even if we can't extract all info, we should still update the pro status if there's an active subscription
        if receipt.hasActiveAutorenewSubscription {
            self.logger.debug("User has active auto-renewable subscription")
            // Update local state immediately
            IAPManager.shared.isProPlan = true
            NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
        }

        guard let productId = receipt.lastAutorenewProductId,
              let transactionId = receipt.lastAutorenewTransactionId,
              let originTransactionId = receipt.lastAutorenewOriginTransactionId,
              let purchaseDate = receipt.purchaseDateForLastAutorenewSubscription,
              let expireDate = receipt.expireDateForLastAutorenewSubscription else {
            self.logger.error("Failed to extract subscription info from receipt adapter.")
            self.logger.debug("ProductId: \(String(describing: receipt.lastAutorenewProductId))")
            self.logger.debug("TransactionId: \(String(describing: receipt.lastAutorenewTransactionId))")
            self.logger.debug("ExpireDate: \(String(describing: receipt.expireDateForLastAutorenewSubscription))")
            return
        }

        self.logger.debug("Extracted info - Product: \(productId), Expire: \(expireDate)")

        RequestManager.shared.updateSubInfo(productId,
                                            transactionId: transactionId,
                                            originTransactionId: originTransactionId,
                                            paymentDate: purchaseDate,
                                            nextPaymentDate: expireDate)
    }
}
