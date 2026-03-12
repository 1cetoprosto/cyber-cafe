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
        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        
        let action = UIAlertAction(title: R.string.global.actionOk(), style: .default) { (action:UIAlertAction) in
            print("You've pressed default");
        }
        
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(_ title: String?, body: String?, action: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: R.string.global.actionOk(), style: .default, handler: { (_) in
            action?()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func showWarning(body: String?, buttonTitle: String, action: @escaping () -> ()) {
        let alertVC = UIAlertController(title: R.string.global.attention(),
                                        message: body,
                                        preferredStyle: .alert)
        
        alertVC.addAction(UIAlertAction(title: R.string.global.cancel(), style: .destructive, handler: { (action) in
            return
        }))
        
        alertVC.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { handler in
            action()
        }))
        
        present(alertVC, animated: true, completion: nil)
    }
    
    func askConfirmOperation(_ info: String, action: @escaping () -> ()) {
        let alertVC = UIAlertController(title: R.string.global.attention(),
                                        message: info,
                                        preferredStyle: .alert)
        
        alertVC.addAction(UIAlertAction(title: R.string.global.cancel(), style: .destructive))
        alertVC.addAction(UIAlertAction(title: R.string.global.confirm(), style: .default, handler: { handler in
            action()
        }))
        
        present(alertVC, animated: true, completion: nil)
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
