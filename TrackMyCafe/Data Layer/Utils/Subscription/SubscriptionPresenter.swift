import Foundation
import StoreKit

struct SubscriptionDisplayInfo {
    let buttonTitle: String
    let termsText: String
    let isTrial: Bool
}

final class SubscriptionPresenter {
    
    static let shared = SubscriptionPresenter()
    
    private init() {}
    
    func getDisplayInfo(for product: SKProduct) -> SubscriptionDisplayInfo {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let priceString = formatter.string(from: product.price) ?? "\(product.price)"
        
        if let introPrice = product.introductoryPrice,
           introPrice.paymentMode == .freeTrial {
            
            // Trial Logic
            let days = introPrice.subscriptionPeriod.numberOfUnits
            let periodUnit = introPrice.subscriptionPeriod.unit
            var daysCount = 7 // Default
            
            if periodUnit == .day { daysCount = days }
            else if periodUnit == .week { daysCount = days * 7 }
            else if periodUnit == .month { daysCount = days * 30 }
            else if periodUnit == .year { daysCount = days * 365 }
            
            return SubscriptionDisplayInfo(
                buttonTitle: R.string.global.tryButtonTitle(daysCount),
                termsText: R.string.global.trialTermsText(priceString),
                isTrial: true
            )
        } else {
            // Regular Price
            return SubscriptionDisplayInfo(
                buttonTitle: R.string.global.subscribeButtonTitle(priceString),
                termsText: R.string.global.noTrialTermsText(),
                isTrial: false
            )
        }
    }
    
    func findBestProduct(in products: [SKProduct]) -> SKProduct? {
        if let monthly = products.first(where: { $0.productIdentifier.contains("month") }) {
            return monthly
        } else {
            return products.first
        }
    }
}
