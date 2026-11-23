//
//  SignInViewModelType.swift
//  TrackMyCafe
//

import Foundation

// MARK: - SignInViewModelType

protocol SignInViewModelType: AnyObject {
    typealias Action = AuthModel.AuthModelAction

    var actionHandler: ((Action) -> Void)? { get set }

    func signIn(email: String, password: String, rememberUser: Bool)
    func signInWithLink(_ link: String, email: String)
    func signInWithLink(_ link: String)
    func signInWithBio()
    func resolvedPendingEmailLinkEmail(from link: String?) -> String?
}