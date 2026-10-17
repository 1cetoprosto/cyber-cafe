//
//  StaffCreateEditViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 13.10.2026.
//

import Foundation

/// ViewModel for creating and editing employees.
/// Handles validation, delegates persistence to `StaffServiceProtocol`, and
/// triggers invite sending after a successful create.
///
/// No Firebase imports here — all Firestore/Auth operations live in `StaffService`.
final class StaffCreateEditViewModel: Loggable {

    private let staffService: StaffServiceProtocol
    private(set) var employee: Employee
    private let isModerator: Bool

    /// Callback invoked after a successful save. Passes `true` for new employees.
    var onSaveSuccess: ((Bool) -> Void)?
    /// Callback invoked when an invite email needs to be sent (after create).
    var onSendInvite: (() -> Void)?

    init(
        employee: Employee? = nil,
        isModerator: Bool = false,
        staffService: StaffServiceProtocol = StaffService()
    ) {
        self.staffService = staffService
        self.isModerator = isModerator
        if let employee {
            self.employee = employee.copy()
        } else {
            self.employee = Employee()
            if isModerator {
                self.employee.role = .moderator
            }
        }
    }

    // MARK: - Field accessors

    var isEditing: Bool {
        employee.firebaseRef != ""
    }

    var isEmailEditable: Bool {
        !isEditing
    }

    var title: String {
        if isEditing {
            return R.string.global.edit()
        }
        return isModerator ? R.string.global.newModerator() : R.string.global.newWaiter()
    }

    var avatarUrl: URL? {
        employee.avatarThumbnailUrl?.url
    }

    var lastName: String { employee.lastName ?? "" }
    var firstName: String { employee.firstName }
    var middleName: String { employee.middleName ?? "" }
    var phone: String { employee.phone ?? "" }
    var email: String { employee.email }
    var address: String { employee.address ?? "" }
    var note: String { employee.comment ?? "" }

    func updateLastName(_ value: String) { employee.lastName = value }
    func updateFirstName(_ value: String) { employee.firstName = value }
    func updateMiddleName(_ value: String) { employee.middleName = value }
    func updatePhone(_ value: String) { employee.phone = value }
    func updateEmail(_ value: String) { employee.email = value }
    func updateAddress(_ value: String) { employee.address = value }
    func updateNote(_ value: String) { employee.comment = value }

    func updateAvatar(filePath: String?, thumbnailPath: String?) {
        employee.avatarUrl = filePath
        employee.avatarThumbnailUrl = thumbnailPath
    }

    // MARK: - Validation

    /// Returns `nil` if valid, otherwise a localized error message.
    func validate() -> String? {
        if employee.firstName.isEmpty {
            return R.string.global.firstNameRequired()
        }
        if employee.email.nilIfEmpty == nil {
            return R.string.global.emailRequired()
        }
        if let email = employee.email.nilIfEmpty, !email.isValid(regex: .email) {
            return R.string.global.emailNotValid()
        }
        return nil
    }

    // MARK: - Save

    /// Persists the employee (create or update) via the staff service.
    /// Returns `nil` on success, or an error message to display.
    func save() async -> String? {
        if let errorMessage = validate() {
            return errorMessage
        }

        if isEditing {
            return await updateEmployee()
        } else {
            return await createEmployee()
        }
    }

    private func createEmployee() async -> String? {
        // Email uniqueness check.
        let roles = await staffService.getRoles(employee.email)
        if (roles ?? []).isEmpty == false {
            return R.string.global.employeeEmailAlreadyExist()
        }

        do {
            try await staffService.createEmployee(employee)
            logSave(isNew: true)
            await MainActor.run { onSendInvite?() }
            return nil
        } catch {
            logger.error("Failed to create employee: \(error.localizedDescription)")
            return R.string.global.wentWrong()
        }
    }

    private func updateEmployee() async -> String? {
        do {
            try await staffService.updateEmployee(employee)
            logSave(isNew: false)
            return nil
        } catch {
            logger.error("Failed to update employee: \(error.localizedDescription)")
            return R.string.global.wentWrong()
        }
    }

    // MARK: - Invite

    func sendInviteEmail() async throws {
        try await staffService.sendInvite(to: employee.email)
    }

    // MARK: - Logging

    func logSave(isNew: Bool) {
        RequestManager.shared.log(
            date: Date(), object: .technicians, action: isNew ? .add : .update,
            description: employee.description)
    }

    func logAvatarUpload(filePath: String) {
        RequestManager.shared.log(
            date: Date(), object: .technicians, action: .add,
            description: R.string.global.uploadedNewEmployeeImageAt(filePath))
    }
}
