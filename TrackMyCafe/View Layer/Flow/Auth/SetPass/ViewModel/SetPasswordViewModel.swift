//
//  SetPasswordViewModel.swift
//  TrackMyCafe
//

import FirebaseAuth
import Foundation
import LocalAuthentication

// MARK: - SetPasswordViewModel

final class SetPasswordViewModel: SetPasswordViewModelType {

    private let bioContext: LAContext?

    init(bioContext: LAContext?) {
        self.bioContext = bioContext
    }

    var shouldOfferBioSetup: Bool {
        bioContext != nil
    }

    func updatePassword(_ password: String) async -> Error? {
        await withCheckedContinuation { continuation in
            Auth.auth().currentUser?.updatePassword(to: password) { error in
                continuation.resume(returning: error)
            }
        }
    }
}