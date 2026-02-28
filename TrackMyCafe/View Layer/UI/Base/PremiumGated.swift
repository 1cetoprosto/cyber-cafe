import UIKit

protocol PremiumGated: UIViewController {
    /// Checks if the user has a premium plan. If not, presents the paywall.
    /// - Returns: `true` if the user is premium, `false` otherwise.
    func checkPremiumOrShowPaywall() -> Bool
}

extension PremiumGated {
    @discardableResult
    func checkPremiumOrShowPaywall() -> Bool {
        let isPremium = IAPManager.shared.isPremiumPlan == true
        if !isPremium {
            let controller = SubscriptionController.makeDefault()
            // Ensure we present on the top-most controller
            if let presented = presentedViewController {
                presented.present(controller, animated: true)
            } else {
                present(controller, animated: true)
            }
            return false
        }
        return true
    }
}
