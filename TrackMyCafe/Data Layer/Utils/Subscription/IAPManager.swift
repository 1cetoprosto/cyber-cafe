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

class IAPManager: NSObject {
    
    static let shared = IAPManager()
    
    // MARK: - Public properties
    var currentSubscription: SubscriptionType {
        guard let subscription = RequestManager.shared.subscription else { return .none }
        if subscription.premiumPlan { return .premium }
        guard subscription.isActive, let productId = subscription.productId else { return .none }
        return SubscriptionType(rawValue: productId) ?? .none
    }
    
    @AppDefaults<Date>(key: "kUserSubscriptionNextPaymentDate")
    public private(set) var nextPaymentDate: Date?
    
    @AppDefaults<Bool>(key: "kUserSubscriptionIsPremiumPlan")
    public private(set) var premiumPlan: Bool?
    
    // MARK: - Public methods
    func updateInfo(_ subscription: Subscription) {
        nextPaymentDate = subscription.nextPaymentDate
        premiumPlan = subscription.premiumPlan
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
        SwiftyStoreKit.purchaseProduct(product) { (result) in
            switch result {
            case .success(let purchaseDetails):
                self.verifySubscription { receipt in
                    if let receipt = receipt {
                        self.updateSubscriptionInfo(receipt)
                        if purchaseDetails.needsFinishTransaction {
                            SwiftyStoreKit.finishTransaction(purchaseDetails.transaction)
                        }
                    }
                    completion?(receipt != nil, nil)
                }
            case .error(let error):
                print(error)
                completion?(false, error.localizedDescription)
            case .deferred(purchase: let purchase):
                print(purchase)
            }
        }
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
                        print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                    case .failed, .purchasing, .deferred:
                        break // do nothing
                    @unknown default:
                        break // do nothing
                }
            }
        }
    }
    
    func verifySubscription(_ completion: ((IAPReceiptAdapterProtocol?) -> Void)? = nil) {
//        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { (result) in
//            switch result {
//                case .success(let receiptData):
//                    let certPath: String?
//                    //            certPath = Bundle.main.path(forResource: "AppleIncRootCertificate", ofType: "cer")
//                    certPath = Bundle.main.path(forResource: "StoreKitTestCertificate", ofType: "cer")
//                    if let receipt = try? InAppReceipt(receiptData: receiptData, rootCertPath: certPath) {
//                        let receiptAdapter = IAPReceiptAdapterLocalValidation(receipt)
//                        completion?(receiptAdapter)
//                    } else {
//                        print("ERROR")
//                        completion?(nil)
//                    }
//                case .error(let error):
//                    print(error)
//                    completion?(nil)
//            }
//        }
        
        let productionValidator = AppleReceiptValidator(service: .production, sharedSecret: kSharedSecret)
        SwiftyStoreKit.verifyReceipt(using: productionValidator, forceRefresh: false) { (result) in
            switch result {
                case .success(let receipt):
                    let receiptAdapter = IAPReceiptAdapterAppleValidation(receipt)
                    completion?(receiptAdapter)
                case .error:
                    let sandboxValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: kSharedSecret)
                    SwiftyStoreKit.verifyReceipt(using: sandboxValidator, forceRefresh: false) { (result) in
                        switch result {
                            case .success(let receipt):
                                let receiptAdapter = IAPReceiptAdapterAppleValidation(receipt)
                                completion?(receiptAdapter)
                            case .error(let error):
                                print(error)
                                completion?(nil)
                        }
                    }
            }
        }
    }
    
    func updateSubscriptionInfo(_ receipt: IAPReceiptAdapterProtocol) {
        guard let productId = receipt.lastAutorenewProductId,
              let transactionId = receipt.lastAutorenewTransactionId,
              let originTransactionId = receipt.lastAutorenewOriginTransactionId,
              let purchaseDate = receipt.purchaseDateForLastAutorenewSubscription,
              let expireDate = receipt.expireDateForLastAutorenewSubscription else { return }
        
        RequestManager.shared.updateSubInfo(productId,
                                            transactionId: transactionId,
                                            originTransactionId: originTransactionId,
                                            paymentDate: purchaseDate,
                                            nextPaymentDate: expireDate)
    }
}
