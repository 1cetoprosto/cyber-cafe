//
//  SignUpViewModelType.swift
//  TrackMyCafe
//

import Foundation

// MARK: - SignUpViewModelType

protocol SignUpViewModelType: AnyObject {
    typealias Action = AuthModel.AuthModelAction

    var actionHandler: ((Action) -> Void)? { get set }

    func signUp(email: String, password: String)
}