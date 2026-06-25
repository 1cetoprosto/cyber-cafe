//
//  DomainCostDataService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 07.11.2025.
//

import Foundation

enum FinanceMutationError: Error {
    case saveFailed
    case updateFailed
    case deleteFailed
    case missingIdentifier
}

struct BalanceScope: Hashable {
    let account: PaymentAccount
    let date: Date

    init(account: PaymentAccount, date: Date) {
        self.account = account
        self.date = Calendar.current.startOfDay(for: date)
    }
}

protocol BalanceJournalServiceProtocol {
    func syncOrder(previous: OrderModel?, current: OrderModel?) async throws -> Set<BalanceScope>
    func syncOpex(previous: OpexExpenseModel?, current: OpexExpenseModel?) async throws
        -> Set<BalanceScope>
    func syncPurchase(previous: PurchaseModel?, current: PurchaseModel?) async throws
        -> Set<BalanceScope>
}

protocol DailyBalanceMaterializerProtocol {
    func materialize(scopes: Set<BalanceScope>) async throws
}

protocol OrderDataServiceProtocol {
    func createOrder(_ order: OrderModel) async throws -> OrderModel
    func updateOrder(previous: OrderModel, current: OrderModel) async throws
    func deleteOrder(_ order: OrderModel) async throws
}

protocol CostDataServiceProtocol {
    func saveCost(_ cost: OpexExpenseModel) async throws
    func updateCost(_ cost: OpexExpenseModel, date: Date, name: String, sum: Double) async throws
    func deleteCost(_ cost: OpexExpenseModel) async throws
}

protocol FinancePersistenceProtocol: AnyObject {
    func saveOrder(order: OrderModel, completion: @escaping (String?) -> Void)
    func updateOrder(_ order: OrderModel, completion: @escaping (Bool) -> Void)
    func deleteOrder(order: OrderModel, completion: @escaping (Bool) -> Void)

    func saveOpexExpense(model: OpexExpenseModel, completion: @escaping (String?) -> Void)
    func updateOpexExpense(model: OpexExpenseModel, completion: @escaping (Bool) -> Void)
    func deleteOpexExpense(model: OpexExpenseModel, completion: @escaping (Bool) -> Void)

    func saveJournalEntry(model: JournalEntryModel, completion: @escaping (String?) -> Void)
    func fetchJournalEntries(completion: @escaping ([JournalEntryModel]) -> Void)

    func saveDailyBalance(model: DailyBalanceModel, completion: @escaping (Bool) -> Void)
    func fetchDailyBalances(
        forAccount account: PaymentAccount,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping ([DailyBalanceModel]) -> Void
    )

    func delete(collection: String, documentId: String, completion: @escaping (Bool) -> Void)
}

extension DomainDatabaseService: FinancePersistenceProtocol {}

final class BalanceJournalService: BalanceJournalServiceProtocol, Loggable {
    private let database: FinancePersistenceProtocol

    init(database: FinancePersistenceProtocol = DomainDatabaseService.shared) {
        self.database = database
    }

    func syncOrder(previous: OrderModel?, current: OrderModel?) async throws -> Set<BalanceScope> {
        let sourceId = current?.id ?? previous?.id ?? ""
        guard !sourceId.isEmpty else {
            throw FinanceMutationError.missingIdentifier
        }

        let newEntries = makeOrderEntries(from: current)
        return try await replaceJournalEntries(
            sourceType: .order,
            sourceId: sourceId,
            newEntries: newEntries
        )
    }

    func syncOpex(previous: OpexExpenseModel?, current: OpexExpenseModel?) async throws
        -> Set<BalanceScope>
    {
        let sourceId = current?.id ?? previous?.id ?? ""
        guard !sourceId.isEmpty else {
            throw FinanceMutationError.missingIdentifier
        }

        let newEntries = makeOpexEntries(from: current)
        return try await replaceJournalEntries(
            sourceType: .opex,
            sourceId: sourceId,
            newEntries: newEntries
        )
    }

    func syncPurchase(previous: PurchaseModel?, current: PurchaseModel?) async throws
        -> Set<BalanceScope>
    {
        let sourceId = current?.id ?? previous?.id ?? ""
        guard !sourceId.isEmpty else {
            throw FinanceMutationError.missingIdentifier
        }

        let newEntries = makePurchaseEntries(from: current)
        return try await replaceJournalEntries(
            sourceType: .purchase,
            sourceId: sourceId,
            newEntries: newEntries
        )
    }

    private func replaceJournalEntries(
        sourceType: JournalSourceType,
        sourceId: String,
        newEntries: [JournalEntryModel]
    ) async throws -> Set<BalanceScope> {
        let existingEntries = await database.fetchJournalEntriesAsync()
            .filter { $0.sourceType == sourceType && $0.sourceId == sourceId }
        let currentEffects = currentEffects(
            from: existingEntries, sourceType: sourceType, sourceId: sourceId)

        let stornoEntries = currentEffects.compactMap { effect -> JournalEntryModel? in
            guard !effect.amount.isApproximatelyZero else { return nil }

            return JournalEntryModel(
                date: effect.date,
                account: effect.account,
                amount: -effect.amount,
                sourceType: sourceType,
                sourceId: sourceId,
                note: stornoNote(from: effect.note)
            )
        }

        for entry in stornoEntries + newEntries where !entry.amount.isApproximatelyZero {
            _ = try await database.saveJournalEntryAsync(entry)
        }

        let affectedScopes = Set(
            stornoEntries.map { BalanceScope(account: $0.account, date: $0.date) }
                + newEntries.map { BalanceScope(account: $0.account, date: $0.date) }
        )
        logger.info("Synced journal for \(sourceType.rawValue): \(sourceId)")
        return affectedScopes
    }

    private func makeOrderEntries(from order: OrderModel?) -> [JournalEntryModel] {
        guard let order else { return [] }

        var entries: [JournalEntryModel] = []
        if !order.cash.isApproximatelyZero {
            entries.append(
                JournalEntryModel(
                    date: order.date,
                    account: .cash,
                    amount: order.cash,
                    sourceType: .order,
                    sourceId: order.id,
                    note: order.note
                )
            )
        }

        if !order.card.isApproximatelyZero {
            entries.append(
                JournalEntryModel(
                    date: order.date,
                    account: .card,
                    amount: order.card,
                    sourceType: .order,
                    sourceId: order.id,
                    note: order.note
                )
            )
        }

        return entries
    }

    private func makeOpexEntries(from expense: OpexExpenseModel?) -> [JournalEntryModel] {
        guard let expense, let account = expense.paymentAccount, !expense.amount.isApproximatelyZero
        else {
            return []
        }

        return [
            JournalEntryModel(
                date: expense.date,
                account: account,
                amount: -expense.amount,
                sourceType: .opex,
                sourceId: expense.id,
                note: expense.note
            )
        ]
    }

    private func makePurchaseEntries(from purchase: PurchaseModel?) -> [JournalEntryModel] {
        guard
            let purchase,
            let account = purchase.paymentAccount,
            !purchase.totalAmount.isApproximatelyZero
        else {
            return []
        }

        return [
            JournalEntryModel(
                date: purchase.date,
                account: account,
                amount: -purchase.totalAmount,
                sourceType: .purchase,
                sourceId: purchase.id
            )
        ]
    }

    private func currentEffects(
        from entries: [JournalEntryModel],
        sourceType: JournalSourceType,
        sourceId: String
    ) -> [(date: Date, account: PaymentAccount, amount: Double, note: String?)] {
        let grouped = Dictionary(grouping: entries) { entry in
            BalanceScope(account: entry.account, date: entry.date)
        }

        return grouped.compactMap { scope, items in
            let amount = items.reduce(0) { $0 + $1.amount }
            guard !amount.isApproximatelyZero else { return nil }

            return (
                date: scope.date,
                account: scope.account,
                amount: amount,
                note: items.last?.note
            )
        }
    }

    private func stornoNote(from note: String?) -> String? {
        guard let note, !note.isEmpty else { return "Storno" }
        return "Storno: \(note)"
    }
}

final class DailyBalanceMaterializer: DailyBalanceMaterializerProtocol, Loggable {
    private let database: FinancePersistenceProtocol
    private let upperBoundDate = Date(timeIntervalSince1970: 4_102_444_800)  // 2100-01-01

    init(database: FinancePersistenceProtocol = DomainDatabaseService.shared) {
        self.database = database
    }

    func materialize(scopes: Set<BalanceScope>) async throws {
        guard !scopes.isEmpty else { return }

        let journalEntries = await database.fetchJournalEntriesAsync()
        let groupedScopes = Dictionary(grouping: scopes, by: \.account)

        for (account, accountScopes) in groupedScopes {
            guard let startDate = accountScopes.map(\.date).min() else { continue }

            let accountEntries = journalEntries.filter { $0.account == account }
            let deltaByDate = Dictionary(grouping: accountEntries) {
                Calendar.current.startOfDay(for: $0.date)
            }.mapValues { entries in
                entries.reduce(0) { $0 + $1.amount }
            }.filter { !$0.value.isApproximatelyZero }

            let existingBalances = await database.fetchDailyBalancesAsync(
                forAccount: account,
                from: startDate,
                to: upperBoundDate
            )
            let existingBalanceIds = Dictionary(
                uniqueKeysWithValues: existingBalances.map {
                    (Calendar.current.startOfDay(for: $0.date), $0.id)
                }
            )

            let datesToProcess = Set(existingBalances.map(\.date)).union(deltaByDate.keys).sorted()
            var runningBalance =
                accountEntries
                .filter { Calendar.current.startOfDay(for: $0.date) < startDate }
                .reduce(0) { $0 + $1.amount }

            for date in datesToProcess {
                let normalizedDate = Calendar.current.startOfDay(for: date)

                if let delta = deltaByDate[normalizedDate] {
                    runningBalance += delta
                    try await database.saveDailyBalanceAsync(
                        DailyBalanceModel(
                            date: normalizedDate,
                            account: account,
                            balance: runningBalance,
                            delta: delta
                        )
                    )
                } else if let existingId = existingBalanceIds[normalizedDate] {
                    try await database.deleteDocumentAsync(
                        collection: FirebaseCollections.dailyBalances,
                        documentId: existingId
                    )
                }
            }
        }

        logger.info("Materialized daily balances for \(scopes.count) scope(s)")
    }
}

final class DomainOrderDataService: OrderDataServiceProtocol {
    private let database: FinancePersistenceProtocol
    private let balanceJournalService: BalanceJournalServiceProtocol
    private let dailyBalanceMaterializer: DailyBalanceMaterializerProtocol

    init(
        database: FinancePersistenceProtocol = DomainDatabaseService.shared,
        balanceJournalService: BalanceJournalServiceProtocol? = nil,
        dailyBalanceMaterializer: DailyBalanceMaterializerProtocol? = nil
    ) {
        self.database = database
        self.balanceJournalService =
            balanceJournalService ?? BalanceJournalService(database: database)
        self.dailyBalanceMaterializer =
            dailyBalanceMaterializer ?? DailyBalanceMaterializer(database: database)
    }

    func createOrder(_ order: OrderModel) async throws -> OrderModel {
        let savedOrderId = try await database.saveOrderAsync(order: order)
        let savedOrder = OrderModel(
            id: savedOrderId,
            date: order.date,
            type: order.type,
            sum: order.sum,
            cash: order.cash,
            card: order.card,
            totalCost: order.totalCost,
            note: order.note
        )

        let scopes = try await balanceJournalService.syncOrder(previous: nil, current: savedOrder)
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
        return savedOrder
    }

    func updateOrder(previous: OrderModel, current: OrderModel) async throws {
        try await database.updateOrderAsync(current)
        let scopes = try await balanceJournalService.syncOrder(previous: previous, current: current)
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
    }

    func deleteOrder(_ order: OrderModel) async throws {
        try await database.deleteOrderAsync(order: order)
        let scopes = try await balanceJournalService.syncOrder(previous: order, current: nil)
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
    }
}

final class DomainCostDataService: CostDataServiceProtocol {
    private let database: FinancePersistenceProtocol
    private let balanceJournalService: BalanceJournalServiceProtocol
    private let dailyBalanceMaterializer: DailyBalanceMaterializerProtocol

    init(
        database: FinancePersistenceProtocol = DomainDatabaseService.shared,
        balanceJournalService: BalanceJournalServiceProtocol? = nil,
        dailyBalanceMaterializer: DailyBalanceMaterializerProtocol? = nil
    ) {
        self.database = database
        self.balanceJournalService =
            balanceJournalService ?? BalanceJournalService(database: database)
        self.dailyBalanceMaterializer =
            dailyBalanceMaterializer ?? DailyBalanceMaterializer(database: database)
    }

    func saveCost(_ cost: OpexExpenseModel) async throws {
        let savedCostId = try await database.saveOpexExpenseAsync(model: cost)
        let savedCost = OpexExpenseModel(
            id: savedCostId,
            date: cost.date,
            categoryId: cost.categoryId,
            amount: cost.amount,
            paymentAccount: cost.paymentAccount,
            note: cost.note
        )
        let scopes = try await balanceJournalService.syncOpex(previous: nil, current: savedCost)
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
    }

    func updateCost(_ cost: OpexExpenseModel, date: Date, name: String, sum: Double) async throws {
        let updatedCost = OpexExpenseModel(
            id: cost.id,
            date: date,
            categoryId: cost.categoryId,
            amount: sum,
            paymentAccount: cost.paymentAccount,
            note: name
        )

        try await database.updateOpexExpenseAsync(model: updatedCost)
        let scopes = try await balanceJournalService.syncOpex(previous: cost, current: updatedCost)
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
    }

    func deleteCost(_ cost: OpexExpenseModel) async throws {
        try await database.deleteOpexExpenseAsync(model: cost)
        let scopes = try await balanceJournalService.syncOpex(previous: cost, current: nil)
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
    }
}

extension FinancePersistenceProtocol {
    func saveOrderAsync(order: OrderModel) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            saveOrder(order: order) { id in
                if let id {
                    continuation.resume(returning: id)
                } else {
                    continuation.resume(throwing: FinanceMutationError.saveFailed)
                }
            }
        }
    }

    func updateOrderAsync(_ order: OrderModel) async throws {
        try await withCheckedThrowingContinuation { continuation in
            updateOrder(order) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: FinanceMutationError.updateFailed)
                }
            }
        }
    }

    func deleteOrderAsync(order: OrderModel) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteOrder(order: order) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: FinanceMutationError.deleteFailed)
                }
            }
        }
    }

    func saveOpexExpenseAsync(model: OpexExpenseModel) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            saveOpexExpense(model: model) { id in
                if let id {
                    continuation.resume(returning: id)
                } else {
                    continuation.resume(throwing: FinanceMutationError.saveFailed)
                }
            }
        }
    }

    func updateOpexExpenseAsync(model: OpexExpenseModel) async throws {
        try await withCheckedThrowingContinuation { continuation in
            updateOpexExpense(model: model) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: FinanceMutationError.updateFailed)
                }
            }
        }
    }

    func deleteOpexExpenseAsync(model: OpexExpenseModel) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteOpexExpense(model: model) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: FinanceMutationError.deleteFailed)
                }
            }
        }
    }

    func saveJournalEntryAsync(_ model: JournalEntryModel) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            saveJournalEntry(model: model) { id in
                if let id {
                    continuation.resume(returning: id)
                } else {
                    continuation.resume(throwing: FinanceMutationError.saveFailed)
                }
            }
        }
    }

    func fetchJournalEntriesAsync() async -> [JournalEntryModel] {
        await withCheckedContinuation { continuation in
            fetchJournalEntries { entries in
                continuation.resume(returning: entries)
            }
        }
    }

    func saveDailyBalanceAsync(_ model: DailyBalanceModel) async throws {
        try await withCheckedThrowingContinuation { continuation in
            saveDailyBalance(model: model) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: FinanceMutationError.saveFailed)
                }
            }
        }
    }

    func fetchDailyBalancesAsync(
        forAccount account: PaymentAccount,
        from startDate: Date,
        to endDate: Date
    ) async -> [DailyBalanceModel] {
        await withCheckedContinuation { continuation in
            fetchDailyBalances(forAccount: account, from: startDate, to: endDate) { balances in
                continuation.resume(returning: balances)
            }
        }
    }

    func deleteDocumentAsync(collection: String, documentId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            delete(collection: collection, documentId: documentId) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: FinanceMutationError.deleteFailed)
                }
            }
        }
    }
}

extension BinaryFloatingPoint {
    fileprivate var isApproximatelyZero: Bool {
        abs(self) < 0.000_1
    }
}
