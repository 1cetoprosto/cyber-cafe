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
        checkProOrShowPaywall(onSuccess: {}, onDenied: {})
    }

    @discardableResult
    func checkProOrShowPaywall(onSuccess: @escaping () -> Void) -> Bool {
        checkProOrShowPaywall(onSuccess: onSuccess, onDenied: {})
    }

    @discardableResult
    func checkProOrShowPaywall(onSuccess: @escaping () -> Void, onDenied: @escaping () -> Void) -> Bool {
        let isPro = IAPManager.shared.isProPlan == true
        if isPro {
            onSuccess()
            return true
        }

        Task { [weak self] in
            guard let self else { return }
            let refreshedIsPro = await IAPManager.shared.refreshProStatusUsingStoreKit2()
            await MainActor.run {
                if refreshedIsPro {
                    onSuccess()
                } else {
                    onDenied()
                    self.presentPaywall(onSuccess: onSuccess)
                }
            }
        }
        return false
    }

    private func presentPaywall(onSuccess: (() -> Void)?) {
        let controller = SubscriptionController.makeDefault()
        controller.onSubscriptionSuccess = { [weak controller] in
            DispatchQueue.main.async {
                if let controller {
                    controller.dismiss(animated: true) {
                        onSuccess?()
                    }
                } else {
                    onSuccess?()
                }
            }
        }

        if let presented = presentedViewController {
            presented.present(controller, animated: true)
        } else {
            present(controller, animated: true)
        }
    }
}
