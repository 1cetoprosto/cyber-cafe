//
//  StaffViewModelTests.swift
//  TrackMyCafeTests
//
//  Unit tests for the Staff module ViewModels.
//  Uses a mock `StaffServiceProtocol` so no Firebase / network calls are made.
//

import XCTest

@testable import TrackMyCafe_Dev

// MARK: - Mock Staff Service

private final class MockStaffService: StaffServiceProtocol {

    // Inputs (configured per test)
    var employees: [Employee] = []
    var deleteEmployeeResult = true
    var getRolesResult: [RoleConfig]? = nil
    var getEmployeeRolesResult: [RoleConfig]? = nil
    var createEmployeeError: Error? = nil
    var updateEmployeeError: Error? = nil
    var sendInviteError: Error? = nil

    // Captured state
    var deleteEmployeeCalled = false
    var createEmployeeCalled = false
    var updateEmployeeCalled = false
    var sendInviteCalled = false
    var lastDeletedEmployee: Employee?
    var lastCreatedEmployee: Employee?
    var lastUpdatedEmployee: Employee?
    var lastInviteEmail: String?

    func deleteEmployee(_ employee: Employee) async -> Bool {
        deleteEmployeeCalled = true
        lastDeletedEmployee = employee
        return deleteEmployeeResult
    }

    func getRoles(_ email: String) async -> [RoleConfig]? {
        getRolesResult
    }

    func getEmployeeRoles(_ email: String) async -> [RoleConfig]? {
        getEmployeeRolesResult
    }

    func createEmployee(_ employee: Employee) async throws {
        createEmployeeCalled = true
        lastCreatedEmployee = employee
        if let error = createEmployeeError { throw error }
        // Simulate the real service assigning a document ID.
        employee.firebaseRef = "generated-employee-ref"
    }

    func updateEmployee(_ employee: Employee) async throws {
        updateEmployeeCalled = true
        lastUpdatedEmployee = employee
        if let error = updateEmployeeError { throw error }
    }

    func sendInvite(to email: String) async throws {
        sendInviteCalled = true
        lastInviteEmail = email
        if let sendInviteError {
            throw sendInviteError
        }
    }
}

// MARK: - Helpers

private func makeEmployee(
    ref: String,
    firstName: String,
    lastName: String? = nil,
    middleName: String? = nil,
    role: Role = .waiter,
    enabled: Bool = true,
    email: String = "employee@test.com"
) -> Employee {
    let e = Employee()
    e.firebaseRef = ref
    e.firstName = firstName
    e.lastName = lastName
    e.middleName = middleName
    e.role = role
    e.enabled = enabled
    e.email = email
    return e
}

// MARK: - StaffCreateEditViewModel Tests

final class StaffCreateEditViewModelTests: XCTestCase {

    private var service: MockStaffService!

    override func setUp() {
        super.setUp()
        service = MockStaffService()
    }

    // MARK: - Validation

    func testValidate_returnsError_whenFirstNameIsEmpty() {
        let vm = StaffCreateEditViewModel(staffService: service)
        vm.updateFirstName("")
        vm.updateEmail("valid@test.com")

        XCTAssertNotNil(vm.validate())
    }

    func testValidate_returnsError_whenEmailIsEmpty() {
        let vm = StaffCreateEditViewModel(staffService: service)
        vm.updateFirstName("John")
        vm.updateEmail("")

        XCTAssertNotNil(vm.validate())
    }

    func testValidate_returnsError_whenEmailFormatIsInvalid() {
        let vm = StaffCreateEditViewModel(staffService: service)
        vm.updateFirstName("John")
        vm.updateEmail("not-an-email")

        XCTAssertNotNil(vm.validate())
    }

    func testValidate_returnsNil_whenInputIsValid() {
        let vm = StaffCreateEditViewModel(staffService: service)
        vm.updateFirstName("John")
        vm.updateEmail("john@test.com")

        XCTAssertNil(vm.validate())
    }

    // MARK: - isEditing / isEmailEditable

    func testIsEditing_isFalse_forNewEmployee() {
        let vm = StaffCreateEditViewModel(staffService: service)
        XCTAssertFalse(vm.isEditing)
        XCTAssertTrue(vm.isEmailEditable)
    }

    func testIsEditing_isTrue_forExistingEmployee() {
        let existing = makeEmployee(ref: "emp-1", firstName: "John")
        let vm = StaffCreateEditViewModel(employee: existing, staffService: service)
        XCTAssertTrue(vm.isEditing)
        XCTAssertFalse(vm.isEmailEditable)
    }

    func testIsModerator_setsDefaultRoleToModerator() {
        let vm = StaffCreateEditViewModel(isModerator: true, staffService: service)
        XCTAssertEqual(vm.employee.role, .moderator)
    }

    func testDefaultRole_isWaiter_forNewEmployee() {
        let vm = StaffCreateEditViewModel(staffService: service)
        XCTAssertEqual(vm.employee.role, .waiter)
    }

    // MARK: - Save (create)

    func testSave_create_returnsError_whenEmailAlreadyExists() async {
        let vm = StaffCreateEditViewModel(staffService: service)
        vm.updateFirstName("John")
        vm.updateEmail("existing@test.com")

        // Simulate an existing role config for this email.
        service.getRolesResult = [
            RoleConfig(
                ref: "role-1", email: "existing@test.com",
                dataRef: "master", userRef: "user-1", role: .waiter,
                onlineVersion: true)
        ]

        let result = await vm.save()

        XCTAssertNotNil(result)
        XCTAssertFalse(service.createEmployeeCalled)
    }

    func testSave_create_succeeds_andSetsFirebaseRef_whenEmailIsFree() async {
        let vm = StaffCreateEditViewModel(staffService: service)
        vm.updateFirstName("John")
        vm.updateEmail("new@test.com")

        service.getRolesResult = nil

        let result = await vm.save()

        XCTAssertNil(result)
        XCTAssertTrue(service.createEmployeeCalled)
        XCTAssertEqual(service.lastCreatedEmployee?.email, "new@test.com")
        // The mock assigns a ref, simulating the real service.
        XCTAssertEqual(vm.employee.firebaseRef, "generated-employee-ref")
        XCTAssertTrue(vm.isEditing)
    }

    func testSave_create_returnsError_whenServiceThrows() async {
        let vm = StaffCreateEditViewModel(staffService: service)
        vm.updateFirstName("John")
        vm.updateEmail("new@test.com")

        service.getRolesResult = nil
        service.createEmployeeError = StaffServiceError.missingMasterUserRef

        let result = await vm.save()

        XCTAssertNotNil(result)
    }

    // MARK: - Save (update)

    func testSave_update_succeeds_whenServiceSucceeds() async {
        let existing = makeEmployee(ref: "emp-1", firstName: "John")
        let vm = StaffCreateEditViewModel(employee: existing, staffService: service)
        vm.updateFirstName("Johnny")

        let result = await vm.save()

        XCTAssertNil(result)
        XCTAssertTrue(service.updateEmployeeCalled)
        XCTAssertEqual(service.lastUpdatedEmployee?.firstName, "Johnny")
    }

    func testSave_update_returnsError_whenServiceThrows() async {
        let existing = makeEmployee(ref: "emp-1", firstName: "John")
        let vm = StaffCreateEditViewModel(employee: existing, staffService: service)

        service.updateEmployeeError = StaffServiceError.missingRoleConfig

        let result = await vm.save()

        XCTAssertNotNil(result)
    }

    // MARK: - Invite

    func testSendInviteEmail_delegatesToService() async {
        let existing = makeEmployee(ref: "emp-1", firstName: "John")
        existing.email = "john@test.com"
        let vm = StaffCreateEditViewModel(employee: existing, staffService: service)

        try? await vm.sendInviteEmail()

        XCTAssertTrue(service.sendInviteCalled)
        XCTAssertEqual(service.lastInviteEmail, "john@test.com")
    }
}

// MARK: - StaffDetailsViewModel Tests

final class StaffDetailsViewModelTests: XCTestCase {

    private var service: MockStaffService!

    override func setUp() {
        super.setUp()
        service = MockStaffService()
    }

    func testFullName_concatenatesAllNameParts() {
        let employee = makeEmployee(
            ref: "emp-1", firstName: "John", lastName: "Doe", middleName: "Michael")
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        XCTAssertEqual(vm.fullName, "Doe John Michael")
    }

    func testShortName_concatenatesLastAndFirst() {
        let employee = makeEmployee(
            ref: "emp-1", firstName: "John", lastName: "Doe", middleName: "Michael")
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        XCTAssertEqual(vm.shortName, "Doe John")
    }

    func testFullName_skipsNilAndEmptyParts() {
        let employee = makeEmployee(ref: "emp-1", firstName: "John")
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        XCTAssertEqual(vm.fullName, "John")
    }

    func testReload_returnsTrueAndUpdatesEmployee_whenFoundInCache() {
        let original = makeEmployee(ref: "emp-1", firstName: "John")
        let updated = makeEmployee(ref: "emp-1", firstName: "Johnny")
        service.employees = [updated]

        let vm = StaffDetailsViewModel(employee: original, staffService: service)

        XCTAssertTrue(vm.reload())
        XCTAssertEqual(vm.employee.firstName, "Johnny")
    }

    func testReload_returnsFalse_whenEmployeeNotInCache() {
        let original = makeEmployee(ref: "emp-1", firstName: "John")
        service.employees = []

        let vm = StaffDetailsViewModel(employee: original, staffService: service)

        XCTAssertFalse(vm.reload())
    }

    func testDeleteEmployee_delegatesToService() async {
        let employee = makeEmployee(ref: "emp-1", firstName: "John")
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        service.deleteEmployeeResult = true

        let success = await vm.deleteEmployee()

        XCTAssertTrue(success)
        XCTAssertTrue(service.deleteEmployeeCalled)
        XCTAssertEqual(service.lastDeletedEmployee?.firebaseRef, "emp-1")
    }

    func testDeleteEmployee_returnsFalse_whenServiceFails() async {
        let employee = makeEmployee(ref: "emp-1", firstName: "John")
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        service.deleteEmployeeResult = false

        let success = await vm.deleteEmployee()

        XCTAssertFalse(success)
    }

    func testResendInvite_delegatesToService() async {
        let employee = makeEmployee(ref: "emp-1", firstName: "John")
        employee.email = "john@test.com"
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        try? await vm.resendInvite()

        XCTAssertTrue(service.sendInviteCalled)
        XCTAssertEqual(service.lastInviteEmail, "john@test.com")
    }

    func testIsEmailClickable_isTrue_forValidEmail() {
        let employee = makeEmployee(ref: "emp-1", firstName: "John")
        employee.email = "john@test.com"
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        XCTAssertTrue(vm.isEmailClickable)
    }

    func testIsPhoneClickable_isFalse_whenPhoneIsNil() {
        let employee = makeEmployee(ref: "emp-1", firstName: "John")
        employee.phone = nil
        let vm = StaffDetailsViewModel(employee: employee, staffService: service)

        XCTAssertFalse(vm.isPhoneClickable)
    }
}

// MARK: - StaffListViewModel Tests

final class StaffListViewModelTests: XCTestCase {

    private var service: MockStaffService!

    override func setUp() {
        super.setUp()
        service = MockStaffService()
    }

    func testReload_filtersByAllowedRolesAndEnabled() {
        let waiter = makeEmployee(ref: "w1", firstName: "Waiter", role: .waiter, enabled: true)
        let disabledWaiter = makeEmployee(
            ref: "w2", firstName: "Disabled", role: .waiter, enabled: false)
        let moderator = makeEmployee(
            ref: "m1", firstName: "Moderator", role: .moderator, enabled: true)
        let admin = makeEmployee(ref: "a1", firstName: "Admin", role: .administrator, enabled: true)

        service.employees = [waiter, disabledWaiter, moderator, admin]

        let vm = StaffListViewModel(
            staffService: service, allowedRoles: [.waiter, .techMod])
        vm.reload()

        XCTAssertEqual(vm.allEmployees.count, 1)
        XCTAssertEqual(vm.allEmployees.first?.firebaseRef, "w1")
    }

    func testReload_moderatorList_includesOnlyModerators() {
        let waiter = makeEmployee(ref: "w1", firstName: "Waiter", role: .waiter, enabled: true)
        let moderator = makeEmployee(
            ref: "m1", firstName: "Moderator", role: .moderator, enabled: true)

        service.employees = [waiter, moderator]

        let vm = StaffListViewModel(
            staffService: service, allowedRoles: [.moderator, .techMod])
        vm.reload()

        XCTAssertEqual(vm.allEmployees.count, 1)
        XCTAssertEqual(vm.allEmployees.first?.firebaseRef, "m1")
    }

    func testFilterContent_filtersByName() {
        let john = makeEmployee(ref: "w1", firstName: "John", lastName: "Doe", role: .waiter)
        let jane = makeEmployee(ref: "w2", firstName: "Jane", lastName: "Smith", role: .waiter)
        service.employees = [john, jane]

        let vm = StaffListViewModel(staffService: service, allowedRoles: [.waiter, .techMod])
        vm.reload()

        vm.filterContent(for: "john")

        XCTAssertEqual(vm.numberOfRows, 1)
        XCTAssertEqual(vm.employee(at: 0).firebaseRef, "w1")
    }

    func testFilterContent_isCaseInsensitive() {
        let john = makeEmployee(ref: "w1", firstName: "John", lastName: "Doe", role: .waiter)
        service.employees = [john]

        let vm = StaffListViewModel(staffService: service, allowedRoles: [.waiter, .techMod])
        vm.reload()

        vm.filterContent(for: "DOE")

        XCTAssertEqual(vm.numberOfRows, 1)
    }

    func testResetSearch_clearsFiltering() {
        let john = makeEmployee(ref: "w1", firstName: "John", lastName: "Doe", role: .waiter)
        let jane = makeEmployee(ref: "w2", firstName: "Jane", lastName: "Smith", role: .waiter)
        service.employees = [john, jane]

        let vm = StaffListViewModel(staffService: service, allowedRoles: [.waiter, .techMod])
        vm.reload()
        vm.filterContent(for: "john")
        XCTAssertEqual(vm.numberOfRows, 1)

        vm.resetSearch()
        XCTAssertEqual(vm.numberOfRows, 2)
    }

    func testDeleteEmployee_delegatesToService() async {
        let waiter = makeEmployee(ref: "w1", firstName: "John", role: .waiter)
        service.employees = [waiter]

        let vm = StaffListViewModel(staffService: service, allowedRoles: [.waiter, .techMod])
        vm.reload()

        service.deleteEmployeeResult = true

        let success = await vm.deleteEmployee(at: 0)

        XCTAssertTrue(success)
        XCTAssertTrue(service.deleteEmployeeCalled)
        XCTAssertEqual(service.lastDeletedEmployee?.firebaseRef, "w1")
    }
}
