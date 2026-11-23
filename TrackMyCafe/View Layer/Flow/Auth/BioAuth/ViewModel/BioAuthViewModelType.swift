//
//  BioAuthViewModelType.swift
//  TrackMyCafe
//

import Foundation
import LocalAuthentication

// MARK: - BioAuthViewModelType

protocol BioAuthViewModelType: AnyObject {
    var biometryDisplayName: String { get }
    var iconUsesTouchID: Bool { get }
    var iconUsesFaceID: Bool { get }

    func enableBioAuth(_ enabled: Bool)
}