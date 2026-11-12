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
        // Cafe-level Pro from the owner's Firebase subscription is enough —
        // staff must not be blocked by a missing local App Store purchase.
        if IAPManager.shared.isProPlan == true
            || IAPManager.shared.hasActiveAccountSubscription
        {
            IAPManager.shared.isProPlan = true
            onSuccess()
            return true
        }

        Task { [weak self] in
            guard let self else { return }
            let refreshedIsPro = await IAPManager.shared.resolveProAccess()
            await MainActor.run {
                if refreshedIsPro {
                    onSuccess()
                } else {
                    onDenied()
                    self.presentSubscriptionRequired(onSuccess: onSuccess)
                }
            }
        }
        return false
    }

    private func presentSubscriptionRequired(onSuccess: (() -> Void)?) {
        // Only the cafe owner can buy/restore. Staff get a clear message instead.
        if UserSession.current.isAuth, !UserSession.current.canManageSubscription {
            showAlert(
                R.string.global.subscription(),
                body: R.string.global.subscriptionAskOwner()
            )
            return
        }

        presentPaywall(onSuccess: onSuccess)
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
