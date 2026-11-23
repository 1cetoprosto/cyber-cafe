//
//  SignUpViewModel.swift
//  TrackMyCafe
//

import Foundation

// MARK: - SignUpViewModel

final class SignUpViewModel: SignUpViewModelType {

    private let authModel: AuthModel

    var actionHandler: ((Action) -> Void)? {
        get { authModel.actionHandler }
        set { authModel.actionHandler = newValue }
    }

    init(authModel: AuthModel = AuthModel()) {
        self.authModel = authModel
    }

    func signUp(email: String, password: String) {
        authModel.signUp(email: email, password: password)
    }
}