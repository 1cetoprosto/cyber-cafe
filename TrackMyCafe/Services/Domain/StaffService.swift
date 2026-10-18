//
//  StaffService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 13.10.2026.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Default implementation of `StaffServiceProtocol` backed by `RequestManager` cache
/// and `FirestoreDatabaseService` write operations.
///
/// This is the only place in the Staff module that talks to Firebase directly,
/// keeping ViewModels free of `FirebaseAuth`/`FirebaseFirestore` imports and
/// making them unit-testable with a mock service.
final class StaffService: StaffServiceProtocol, Loggable {

    /// The establishment's Firestore document reference (`Users/{masterUserRef}`).
    ///
    /// Built from `UserSession.current.masterUserRef` rather than relying on
    /// `RequestManager.shared.mainRef` (an implicitly-unwrapped optional that may
    /// be nil if the session was restored from an older Keychain entry).
    private var mainRef: DocumentReference? {
        guard let masterUserRef = UserSession.current.masterUserRef else { return nil }
        return Firestore.firestore()
            .collection(FirebaseCollections.legacyUsers)
            .document(masterUserRef)
    }

    // MARK: - Read

    var employees: [Employee] {
        RequestManager.shared.employees
    }

    func getRoles(_ email: String) async -> [RoleConfig]? {
        await FirestoreDatabaseService.getRoles(email.trimmed.lowercased())
    }

    func getEmployeeRoles(_ email: String) async -> [RoleConfig]? {
        await FirestoreDatabaseService.getEmployeeRoles(email.trimmed.lowercased())
    }

    // MARK: - Delete

    func deleteEmployee(_ employee: Employee) async -> Bool {
        await FirestoreDatabaseService.deleteEmployee(employee)
    }

    // MARK: - Create

    func createEmployee(_ employee: Employee) async throws {
        guard let masterUserRef = UserSession.current.masterUserRef else {
            throw StaffServiceError.missingMasterUserRef
        }
        guard let mainRef = mainRef else {
            throw StaffServiceError.missingMainRef
        }

        let db = Firestore.firestore()

        // Generate a role config linking the employee's email to the establishment.
        let roleRef = db.collection(FirebaseCollections.users).document()
        let roleConfig = RoleConfig(
            ref: roleRef.documentID,
            email: employee.email,
            dataRef: masterUserRef,
            userRef: roleRef.documentID,
            role: employee.role,
            onlineVersion: true
        )

        // Generate the employee document ID and assign it back to the model.
        // Use the legacy PascalCase name ("Technicians") to match the path
        // `RequestManager` listens on — NOT `FirebaseCollections.technicians`
        // ("technicians"), which is a different collection.
        let employeeRef = mainRef.collection(FirebaseCollections.legacyTechnicians).document()
        employee.firebaseRef = employeeRef.documentID

        let batch = db.batch()
        batch.setData(
            roleConfig.forDatabase(),
            forDocument: db.collection(FirebaseCollections.roles).document(roleConfig.firebaseRef)
        )
        batch.setData(
            employee.forDatabase(),
            forDocument: employeeRef
        )

        try await batch.commit()
    }

    // MARK: - Update

    func updateEmployee(_ employee: Employee) async throws {
        guard let masterUserRef = UserSession.current.masterUserRef else {
            throw StaffServiceError.missingMasterUserRef
        }
        guard let mainRef = mainRef else {
            throw StaffServiceError.missingMainRef
        }

        let existingRoles = await getEmployeeRoles(employee.email) ?? []
        guard let userDataKey = existingRoles.first?.userRef else {
            throw StaffServiceError.missingRoleConfig
        }

        var removeRoles = existingRoles.filter { $0.role != employee.role }
        var addRoles: [RoleConfig] = []

        if !existingRoles.contains(where: { $0.role == employee.role }) {
            let roleConfig = RoleConfig(
                ref: Firestore.firestore().collection(FirebaseCollections.users).document()
                    .documentID,
                email: employee.email,
                dataRef: masterUserRef,
                userRef: userDataKey,
                role: employee.role,
                onlineVersion: true
            )
            addRoles.append(roleConfig)
        }

        let db = Firestore.firestore()
        let employeeRef = mainRef.collection(FirebaseCollections.legacyTechnicians).document(
            employee.firebaseRef)
        let batch = db.batch()

        addRoles.forEach {
            batch.setData(
                $0.forDatabase(),
                forDocument: db.collection(FirebaseCollections.roles).document($0.firebaseRef)
            )
        }
        removeRoles.forEach {
            batch.deleteDocument(db.collection(FirebaseCollections.roles).document($0.firebaseRef))
        }

        batch.setData(
            employee.forDatabase(),
            forDocument: employeeRef
        )

        try await batch.commit()
    }

    // MARK: - Invite

    func sendInvite(to email: String) async throws {
        let normalizedEmail = email.trimmed.lowercased()
        guard normalizedEmail.isValid(regex: .email) else {
            logger.error("Failed to send staff invite: invalid email \(normalizedEmail)")
            throw StaffServiceError.invalidEmail
        }

        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = AuthModel.emailLinkContinueURL(for: normalizedEmail)
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier ?? "")
        logger.notice(
            """
            Sending staff invite to \(normalizedEmail).
            continueURL=\(actionCodeSettings.url?.absoluteString ?? "nil")
            bundleId=\(Bundle.main.bundleIdentifier ?? "nil")
            """
        )
        actionCodeSettings.setAndroidPackageName(
            Config.androidBundle,
            installIfNotAvailable: true,
            minimumVersion: Config.androidVersion
        )

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendSignInLink(
                toEmail: normalizedEmail,
                actionCodeSettings: actionCodeSettings
            ) { error in
                if let error {
                    self.logger.error(
                        "Failed to send staff invite to \(normalizedEmail): \(error.localizedDescription)"
                    )
                    continuation.resume(throwing: error)
                } else {
                    AuthModel.rememberPendingEmailLinkEmail(normalizedEmail)
                    self.logger.notice("Staff invite sent to \(normalizedEmail)")
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Errors

enum StaffServiceError: LocalizedError {
    case missingMasterUserRef
    case missingMainRef
    case missingRoleConfig
    case invalidEmail

    var errorDescription: String? {
        switch self {
        case .missingMasterUserRef:
            return "Master user reference is not available."
        case .missingMainRef:
            return "Establishment reference is not available."
        case .missingRoleConfig:
            return "No role config found for this employee."
        case .invalidEmail:
            return "Email is not valid."
        }
    }
}
