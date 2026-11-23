//
//  ForgotPassViewModelType.swift
//  TrackMyCafe
//

import Foundation

// MARK: - ForgotPassViewModelType

protocol ForgotPassViewModelType: AnyObject {
    typealias Action = AuthModel.AuthModelAction

    var actionHandler: ((Action) -> Void)? { get set }

    func sendPasswordReset(_ email: String)
}