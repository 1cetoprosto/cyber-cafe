//
//  BioAuthViewModel.swift
//  TrackMyCafe
//

import Foundation
import LocalAuthentication

// MARK: - BioAuthViewModel

final class BioAuthViewModel: BioAuthViewModelType {

    private let context: LAContext

    init(context: LAContext) {
        self.context = context
    }

    var biometryDisplayName: String {
        switch context.biometryType {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID, .none:
            return ""
        @unknown default:
            return ""
        }
    }

    var iconUsesTouchID: Bool {
        context.biometryType == .touchID
    }

    var iconUsesFaceID: Bool {
        context.biometryType == .faceID
    }

    func enableBioAuth(_ enabled: Bool) {
        UserSession.current.enableBioAuth(enabled)
    }
}