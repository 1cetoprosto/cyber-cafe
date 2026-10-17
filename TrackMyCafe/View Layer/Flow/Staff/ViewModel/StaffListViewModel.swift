//
//  StaffListViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 13.10.2026.
//

import Foundation

/// ViewModel for employee list screens (Waiters, Moderators).
/// Handles role-based filtering, search, and deletion.
final class StaffListViewModel: Loggable {

    private let staffService: StaffServiceProtocol
    private let allowedRoles: [Role]
    private var employees: [Employee] = []
    private var filteredEmployees: [Employee] = []

    init(staffService: StaffServiceProtocol = StaffService(), allowedRoles: [Role]) {
        self.staffService = staffService
        self.allowedRoles = allowedRoles
    }

    // MARK: - Data

    /// Reloads employees from the service cache (called when the `.employeesInfoReload`
    /// notification fires or the screen appears).
    func reload() {
        employees = staffService.employees
            .filter { allowedRoles.contains($0.role) }
            .filter { $0.enabled }
    }

    /// Role-filtered employees (search filtering is handled by the base list controller).
    var allEmployees: [Employee] {
        employees
    }

    var numberOfRows: Int {
        isFiltering ? filteredEmployees.count : employees.count
    }

    func employee(at index: Int) -> Employee {
        isFiltering ? filteredEmployees[index] : employees[index]
    }

    // MARK: - Search

    private var isFiltering = false

    func filterContent(for searchText: String) {
        isFiltering = !searchText.isEmpty
        filteredEmployees = employees.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    func resetSearch() {
        isFiltering = false
    }

    // MARK: - Delete

    func deleteEmployee(at index: Int) async -> Bool {
        let target = employee(at: index)
        let success = await staffService.deleteEmployee(target)
        if success {
            logger.notice("Employee \(target.firebaseRef ?? "") deleted successfully")
        } else {
            logger.error("Failed to delete employee \(target.firebaseRef ?? "")")
        }
        return success
    }
}
