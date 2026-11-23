//
//  SignInViewModel.swift
//  TrackMyCafe
//

import Foundation

// MARK: - SignInViewModel

final class SignInViewModel: SignInViewModelType {

    private let authModel: AuthModel

    var actionHandler: ((Action) -> Void)? {
        get { authModel.actionHandler }
        set { authModel.actionHandler = newValue }
    }

    init(authModel: AuthModel = AuthModel()) {
        self.authModel = authModel
    }

    func signIn(email: String, password: String, rememberUser: Bool) {
        authModel.signIn(email: email, password: password, rememberUser: rememberUser)
    }

    func signInWithLink(_ link: String, email: String) {
        authModel.signInWithLink(link, email: email)
    }

    func signInWithLink(_ link: String) {
        authModel.signInWithLink(link)
    }

    func signInWithBio() {
        authModel.signInWithBio()
    }

    func resolvedPendingEmailLinkEmail(from link: String?) -> String? {
        AuthModel.resolvedPendingEmailLinkEmail(from: link)
    }
}