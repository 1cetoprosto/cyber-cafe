//
//  StaffDetailsViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 13.10.2026.
//

import Foundation

/// ViewModel for the employee details screen.
/// Owns the employee data and exposes operations (delete, resend invite).
///
/// No Firebase imports here — all Firestore/Auth operations live in `StaffService`.
final class StaffDetailsViewModel: Loggable {

    private let staffService: StaffServiceProtocol
    private(set) var employee: Employee

    init(employee: Employee, staffService: StaffServiceProtocol = StaffService()) {
        self.employee = employee
        self.staffService = staffService
    }

    // MARK: - Display data

    var fullName: String {
        [employee.lastName, employee.firstName, employee.middleName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var shortName: String {
        [employee.lastName, employee.firstName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var roleName: String {
        employee.role.name
    }

    var avatarUrl: String? {
        employee.avatarThumbnailUrl ?? employee.avatarUrl
    }

    var phone: String {
        employee.phone?.nilIfEmpty ?? R.string.global.noSpecified()
    }

    /// Raw phone value (without "Not specified" fallback) for tel:// links.
    var rawPhone: String? {
        employee.phone?.nilIfEmpty
    }

    var email: String {
        employee.email
    }

    var address: String {
        employee.address?.nilIfEmpty ?? R.string.global.noSpecified()
    }

    var note: String {
        employee.comment?.nilIfEmpty ?? R.string.global.noSpecified()
    }

    var isPhoneClickable: Bool {
        employee.phone?.isValid(regex: .phone) == true
    }

    var isEmailClickable: Bool {
        employee.email.isValid(regex: .email)
    }

    // MARK: - Reload

    /// Refreshes the employee from the service cache after a change notification.
    /// Returns `false` if the employee no longer exists (e.g. was deleted).
    @discardableResult
    func reload() -> Bool {
        if let updated = staffService.employees.first(where: {
            $0.firebaseRef == employee.firebaseRef
        }) {
            employee = updated
            return true
        }
        return false
    }

    // MARK: - Delete

    func deleteEmployee() async -> Bool {
        let success = await staffService.deleteEmployee(employee)
        if success {
            logger.notice("Employee \(employee.firebaseRef ?? "") deleted successfully")
        } else {
            logger.error("Failed to delete employee \(employee.firebaseRef ?? "")")
        }
        return success
    }

    func logDeletion() {
        RequestManager.shared.log(
            date: Date(), object: FirebaseCollections.legacyTechnicians, action: .delete,
            description: employee.description
        )
    }

    // MARK: - Resend invite

    /// Sends a sign-in link to the employee's email via the staff service.
    func resendInvite() async throws {
        try await staffService.sendInvite(to: employee.email)
    }
}
