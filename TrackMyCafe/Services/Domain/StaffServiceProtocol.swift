//
//  StaffServiceProtocol.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 13.10.2026.
//

import Foundation

/// Abstracts staff data access for the Staff module so ViewModels don't depend on
/// `RequestManager.shared`, `FirestoreDatabaseService`, or Firebase directly.
protocol StaffServiceProtocol {
    /// All employees of the current establishment (snapshot cache).
    var employees: [Employee] { get }

    /// Deletes an employee and their roles. Returns `true` on success.
    func deleteEmployee(_ employee: Employee) async -> Bool

    /// Fetches all role configs for the given email.
    func getRoles(_ email: String) async -> [RoleConfig]?

    /// Fetches role configs belonging to the current establishment (master user).
    func getEmployeeRoles(_ email: String) async -> [RoleConfig]?

    /// Creates a new employee document + role config in a single Firestore batch.
    /// Sets `employee.firebaseRef` to the generated document ID.
    /// Throws on failure.
    func createEmployee(_ employee: Employee) async throws

    /// Updates an existing employee document and reconciles role configs
    /// (removes roles that no longer match, adds the new one if missing).
    /// Throws on failure.
    func updateEmployee(_ employee: Employee) async throws

    /// Sends a Firebase sign-in link invite to the given email.
    /// Throws the underlying Firebase error if the request fails.
    func sendInvite(to email: String) async throws
}
