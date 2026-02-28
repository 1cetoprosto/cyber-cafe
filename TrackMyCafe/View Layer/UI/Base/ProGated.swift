//
//  ProGated.swift (Should be renamed to ProGated.swift)
//  TrackMyCafe
//

import UIKit

protocol ProGated: UIViewController {
    /// Checks if the user has a pro plan. If not, presents the paywall.
    /// - Returns: `true` if the user is pro, `false` otherwise.
    func checkProOrShowPaywall() -> Bool
}

extension ProGated {
    @discardableResult
    func checkProOrShowPaywall() -> Bool {
        let isPro = IAPManager.shared.isProPlan == true
        if !isPro {
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
