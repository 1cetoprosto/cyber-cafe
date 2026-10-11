//
//  SettingListViewController+Extension.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import FirebaseAuth
import SVProgressHUD
import UIKit

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

        Task { [weak self] in
            guard let self else { return }
            do {
                try await FirestoreDatabaseService.shared.deleteUserAndRoles()
                try await Auth.auth().currentUser?.delete()
                await MainActor.run {
                    SVProgressHUD.dismiss()
                    UserSession.logOut()
                    self.navigateToLogin()
                }
            } catch let error as NSError {
                await MainActor.run {
                    SVProgressHUD.dismiss()
                    if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        self.showReauthAlert()
                    } else {
                        self.showErrorAlert(message: error.localizedDescription)
                    }
                }
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
