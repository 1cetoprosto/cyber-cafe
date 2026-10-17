//
//  UIViewController+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation
import UIKit

extension UIViewController {

    func showAlert(_ title: String?, body: String?) {
        PopupFactory.showPopup(title: title ?? "", description: body ?? "")
    }

    func showAlert(_ title: String?, body: String?, action: (() -> Void)? = nil) {
        PopupFactory.showPopup(title: title ?? "", description: body ?? "", buttonAction: action)
    }

    func showWarning(body: String?, buttonTitle: String, action: @escaping () -> Void) {
        PopupFactory.showPopup(
            title: R.string.global.attention(),
            description: body ?? "",
            buttonTitle: buttonTitle,
            buttonAction: action
        )
    }

    func askConfirmOperation(_ info: String, action: @escaping () -> Void) {
        PopupFactory.showPopup(
            title: R.string.global.attention(),
            description: info,
            buttonTitle: R.string.global.confirm(),
            buttonAction: action
        )
    }

    /// RBAC guard: dismisses/pops the screen if the current user's role is not
    /// in the allowed set. Returns `true` when access is granted.
    @discardableResult
    func requiresRole(_ allowedRoles: Set<Role>) -> Bool {
        guard let role = UserSession.current.role, allowedRoles.contains(role) else {
            showAlert(
                R.string.global.accessDenied(),
                body: R.string.global.noPermissionMessage()
            ) { [weak self] in
                if let nav = self?.navigationController {
                    nav.popViewController(animated: true)
                } else {
                    self?.dismiss(animated: true)
                }
            }
            return false
        }
        return true
    }

    static func topMostViewController(base: UIViewController? = UIApplication.shared.activeKeyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        
        if let split = base as? UISplitViewController {
            return topMostViewController(base: split.viewControllers.last)
        }
        
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        
        return base
    }
}

extension UIApplication {
    var activeKeyWindow: UIWindow? {
        let scenes = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
        
        for scene in scenes {
            if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow
            }
        }
        
        return scenes.first?.windows.first
    }
}
