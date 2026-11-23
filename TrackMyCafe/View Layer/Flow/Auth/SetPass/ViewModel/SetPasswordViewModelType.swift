//
//  SetPasswordViewModelType.swift
//  TrackMyCafe
//

import Foundation
import LocalAuthentication

// MARK: - SetPasswordViewModelType

protocol SetPasswordViewModelType: AnyObject {
    var shouldOfferBioSetup: Bool { get }

    func updatePassword(_ password: String) async -> Error?
}