//
//  ForgotPassViewModel.swift
//  TrackMyCafe
//

import Foundation

// MARK: - ForgotPassViewModel

final class ForgotPassViewModel: ForgotPassViewModelType {

    private let authModel: AuthModel

    var actionHandler: ((Action) -> Void)? {
        get { authModel.actionHandler }
        set { authModel.actionHandler = newValue }
    }

    init(authModel: AuthModel = AuthModel()) {
        self.authModel = authModel
    }

    func sendPasswordReset(_ email: String) {
        authModel.sendPasswordReset(email)
    }
}