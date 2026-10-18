//
//  StaffCategoriesViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 18.10.2026.
//

import Foundation

/// Supplies the establishment owner's profile data to the staff categories screen.
///
/// Kept behind a protocol so `StaffCategoriesController` never touches
/// `RequestManager` directly and the view model stays unit-testable with a stub.
protocol OwnerProfileProviding {
    var ownerDisplayName: String { get }
}

/// Default implementation backed by `RequestManager`'s current admin profile.
struct RequestManagerOwnerProfile: OwnerProfileProviding {
    var ownerDisplayName: String {
        RequestManager.shared.admin.fullName
    }
}

/// ViewModel for `StaffCategoriesController`.
/// Exposes display-ready data for the owner row without leaking services into the VC.
final class StaffCategoriesViewModel {

    private let ownerProfile: OwnerProfileProviding

    init(ownerProfile: OwnerProfileProviding = RequestManagerOwnerProfile()) {
        self.ownerProfile = ownerProfile
    }

    /// Owner's full name, falling back to the localized "Administrator" role name
    /// when the profile has no name yet.
    var ownerDisplayName: String {
        let name = ownerProfile.ownerDisplayName
        return name.isEmpty ? R.string.global.roleAdmin() : name
    }
}
