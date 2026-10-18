//
//  TestSupport.swift
//  TrackMyCafeTests
//
//  Shared mocks and helpers used across the domain test suites.
//

import Foundation

@testable import TrackMyCafe_Dev

// MARK: - Helpers

func makeDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return Calendar.current.date(from: components) ?? Date()
}

func makeUserDefaultsSuite() -> UserDefaults {
    let suiteName = "TrackMyCafeTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName) ?? .standard
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

// MARK: - Value snapshots

struct JournalEntrySnapshot: Hashable {
    let account: PaymentAccount
    let amount: Double

    init(account: PaymentAccount, amount: Double) {
        self.account = account
        self.amount = amount
    }

    init(entry: JournalEntryModel) {
        self.init(account: entry.account, amount: entry.amount)
    }

}

struct DeletedDocument: Equatable {
    let collection: String
    let documentId: String
}

// MARK: - Mocks

final class MockFinancePersistence: FinancePersistenceProtocol {
    var nextSavedOrderId = "saved-order-id"
    var nextSavedOpexId = "saved-opex-id"
    var journalEntries: [JournalEntryModel] = []
    var dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]] = [:]

    var savedJournalEntries: [JournalEntryModel] = []
    var savedDailyBalances: [DailyBalanceModel] = []
    var deletedDocuments: [DeletedDocument] = []
    var savedOpexModels: [OpexExpenseModel] = []

    func saveOrder(order: OrderModel) async -> String? {
        nextSavedOrderId
    }

    func updateOrder(_ order: OrderModel) async -> Bool {
        true
    }

    func deleteOrder(order: OrderModel) async -> Bool {
        true
    }

    func saveOpexExpense(model: OpexExpenseModel) async -> String? {
        savedOpexModels.append(model)
        return nextSavedOpexId
    }

    func updateOpexExpense(model: OpexExpenseModel) async {
    }

    func deleteOpexExpense(model: OpexExpenseModel) async -> Bool {
        true
    }

    func saveJournalEntry(model: JournalEntryModel) async -> String? {
        savedJournalEntries.append(model)
        return model.id
    }

    func fetchJournalEntries() async -> [JournalEntryModel] {
        journalEntries
    }

    func saveDailyBalance(model: DailyBalanceModel) async -> Bool {
        savedDailyBalances.append(model)
        return true
    }

    func fetchDailyBalances(
        forAccount account: PaymentAccount,
        from startDate: Date,
        to endDate: Date
    ) async -> [DailyBalanceModel] {
        let balances = dailyBalancesByAccount[account] ?? []
        return balances.filter { $0.date >= startDate && $0.date <= endDate }
    }

    func delete(collection: String, documentId: String) async -> Bool {
        deletedDocuments.append(
            DeletedDocument(collection: collection, documentId: documentId)
        )
        return true
    }
}

final class MockBalanceJournalService: BalanceJournalServiceProtocol {
    var opexScopesToReturn: Set<BalanceScope> = []
    private(set) var lastPreviousOpex: OpexExpenseModel?
    private(set) var lastCurrentOpex: OpexExpenseModel?

    func syncOrder(previous: OrderModel?, current: OrderModel?) async throws -> Set<BalanceScope> {
        []
    }

    func syncOpex(previous: OpexExpenseModel?, current: OpexExpenseModel?) async throws -> Set<
        BalanceScope
    > {
        lastPreviousOpex = previous
        lastCurrentOpex = current
        return opexScopesToReturn
    }

    func syncPurchase(previous: PurchaseModel?, current: PurchaseModel?) async throws -> Set<
        BalanceScope
    > {
        []
    }

    func syncManual(sourceId: String, newEntries: [JournalEntryModel]) async throws -> Set<
        BalanceScope
    > {
        []
    }
}

final class MockDailyBalanceMaterializer: DailyBalanceMaterializerProtocol {
    private(set) var receivedScopes: Set<BalanceScope> = []

    func materialize(scopes: Set<BalanceScope>) async throws {
        receivedScopes = scopes
    }
}

final class MockFinanceHistorySourceFetcher: FinanceHistorySourceFetching {
    var orders: [OrderModel] = []
    var expenses: [OpexExpenseModel] = []
    var purchases: [PurchaseModel] = []

    func fetchOrders() async -> [OrderModel] {
        orders
    }

    func fetchOpexExpenses() async -> [OpexExpenseModel] {
        expenses
    }

    func fetchPurchases() async -> [PurchaseModel] {
        purchases
    }
}
