//
//  SettingListViewController+Extension.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import UIKit
import FirebaseAuth
import SVProgressHUD

extension SettingListViewController {

    func showDeleteAccountConfirmation() {
        PopupFactory.showDestructivePopup(
            title: R.string.global.deleteAccountTitle(),
            description: R.string.global.deleteAccountMessage(),
            buttonTitle: R.string.global.delete()
        ) {
            self.performAccountDeletion()
        }
    }

    private func performAccountDeletion() {
        SVProgressHUD.show(withStatus: R.string.global.deleting())

        FirestoreDatabaseService.shared.deleteUserAndRoles { [weak self] result in
            switch result {
            case .success:
                Auth.auth().currentUser?.delete { error in
                    SVProgressHUD.dismiss()
                    if let error = error as NSError? {
                        // Requires recent login
                        if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                            self?.showReauthAlert()
                        } else {
                            self?.showErrorAlert(message: error.localizedDescription)
                        }
                    } else {
                        // Success
                        UserSession.logOut()
                        self?.navigateToLogin()
                    }
                }
            case .failure(let error):
                SVProgressHUD.dismiss()
                self?.showErrorAlert(message: error.localizedDescription)
            }
        }
    }

    private func showReauthAlert() {
        PopupFactory.showPopup(
            title: R.string.global.authenticationRequired(),
            description: R.string.global.reauthMessage(),
            buttonTitle: R.string.global.actionOk()
        ) {
            UserSession.logOut()
            self.navigateToLogin()
        }
    }

    private func showErrorAlert(message: String) {
        PopupFactory.showPopup(
            title: R.string.global.error(),
            description: message
        )
    }

    private func navigateToLogin() {
        if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.start()
        }
    }
}
