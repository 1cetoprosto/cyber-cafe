import Foundation

protocol FinanceHistorySourceFetching {
    func fetchOrders(completion: @escaping ([OrderModel]) -> Void)
    func fetchOpexExpenses(completion: @escaping ([OpexExpenseModel]) -> Void)
    func fetchPurchases(completion: @escaping ([PurchaseModel]) -> Void)
}

extension DomainDatabaseService: FinanceHistorySourceFetching {}

final class FinanceHistoryBackfillService: Loggable {
    private let sourceFetcher: FinanceHistorySourceFetching
    private let persistence: FinancePersistenceProtocol
    private let dailyBalanceMaterializer: DailyBalanceMaterializerProtocol
    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(
        sourceFetcher: FinanceHistorySourceFetching = DomainDatabaseService.shared,
        persistence: FinancePersistenceProtocol = DomainDatabaseService.shared,
        dailyBalanceMaterializer: DailyBalanceMaterializerProtocol? = nil,
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.sourceFetcher = sourceFetcher
        self.persistence = persistence
        self.dailyBalanceMaterializer =
            dailyBalanceMaterializer ?? DailyBalanceMaterializer(database: persistence)
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    @discardableResult
    func runIfNeeded() async throws -> Bool {
        guard !userDefaults.bool(forKey: UserDefaultsKeys.financeHistoryBackfillCompleted) else {
            logger.info("Finance history backfill already completed, skipping")
            return false
        }

        let plan = await makePlan()

        for expectedEntry in plan.missingEntries {
            _ = try await persistence.saveJournalEntryAsync(expectedEntry.entry)
        }

        try await dailyBalanceMaterializer.materialize(scopes: plan.materializationScopes)

        userDefaults.set(true, forKey: UserDefaultsKeys.financeHistoryBackfillCompleted)
        userDefaults.set(Date(), forKey: UserDefaultsKeys.financeHistoryBackfillCompletedAt)

        logger.info(
            "Finance history backfill completed. Created \(plan.missingEntries.count) entries, rematerialized \(plan.materializationScopes.count) scope(s)"
        )

        return true
    }

    private func makePlan() async -> FinanceHistoryBackfillPlan {
        async let orders = sourceFetcher.fetchOrdersAsync()
        async let expenses = sourceFetcher.fetchOpexExpensesAsync()
        async let purchases = sourceFetcher.fetchPurchasesAsync()
        async let existingEntries = persistence.fetchJournalEntriesAsync()

        let expectedEntries =
            makeExpectedEntries(
                orders: await orders,
                expenses: await expenses,
                purchases: await purchases
            )
        let existingKeys = Set(
            await existingEntries
                .filter { $0.sourceType != .manual }
                .map { FinanceExpectedJournalEntry.MatchKey(entry: $0, calendar: calendar) }
        )
        let missingEntries = expectedEntries.filter { !existingKeys.contains($0.matchKey) }
        let materializationScopes = makeMaterializationScopes(from: expectedEntries)

        return FinanceHistoryBackfillPlan(
            missingEntries: missingEntries,
            materializationScopes: materializationScopes
        )
    }

    private func makeExpectedEntries(
        orders: [OrderModel],
        expenses: [OpexExpenseModel],
        purchases: [PurchaseModel]
    ) -> [FinanceExpectedJournalEntry] {
        let orderEntries = orders.flatMap { order -> [FinanceExpectedJournalEntry] in
            var entries: [FinanceExpectedJournalEntry] = []

            if !order.cash.isEffectivelyZero {
                entries.append(
                    makeExpectedEntry(
                        id: makeDocumentId(sourceType: .order, sourceId: order.id, account: .cash),
                        date: order.date,
                        account: .cash,
                        amount: order.cash,
                        sourceType: .order,
                        sourceId: order.id,
                        note: order.note
                    )
                )
            }

            if !order.card.isEffectivelyZero {
                entries.append(
                    makeExpectedEntry(
                        id: makeDocumentId(sourceType: .order, sourceId: order.id, account: .card),
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

        let expenseEntries = expenses.compactMap { expense -> FinanceExpectedJournalEntry? in
            guard
                let account = expense.paymentAccount,
                !expense.amount.isEffectivelyZero
            else {
                return nil
            }

            return makeExpectedEntry(
                id: makeDocumentId(sourceType: .opex, sourceId: expense.id, account: account),
                date: expense.date,
                account: account,
                amount: -expense.amount,
                sourceType: .opex,
                sourceId: expense.id,
                note: expense.note
            )
        }

        let purchaseEntries = purchases.compactMap { purchase -> FinanceExpectedJournalEntry? in
            guard
                let account = purchase.paymentAccount,
                !purchase.totalAmount.isEffectivelyZero
            else {
                return nil
            }

            return makeExpectedEntry(
                id: makeDocumentId(sourceType: .purchase, sourceId: purchase.id, account: account),
                date: purchase.date,
                account: account,
                amount: -purchase.totalAmount,
                sourceType: .purchase,
                sourceId: purchase.id,
                note: nil
            )
        }

        return orderEntries + expenseEntries + purchaseEntries
    }

    private func makeExpectedEntry(
        id: String,
        date: Date,
        account: PaymentAccount,
        amount: Double,
        sourceType: JournalSourceType,
        sourceId: String,
        note: String?
    ) -> FinanceExpectedJournalEntry {
        FinanceExpectedJournalEntry(
            entry: JournalEntryModel(
                id: id,
                date: date,
                account: account,
                amount: amount,
                sourceType: sourceType,
                sourceId: sourceId,
                note: note
            ),
            calendar: calendar
        )
    }

    private func makeMaterializationScopes(
        from expectedEntries: [FinanceExpectedJournalEntry]
    ) -> Set<BalanceScope> {
        let earliestDateByAccount = Dictionary(grouping: expectedEntries, by: \.entry.account)
            .compactMapValues { entries in
                entries.map { calendar.startOfDay(for: $0.entry.date) }.min()
            }

        return Set(
            earliestDateByAccount.map { account, date in
                BalanceScope(account: account, date: date)
            }
        )
    }

    private func makeDocumentId(
        sourceType: JournalSourceType,
        sourceId: String,
        account: PaymentAccount
    ) -> String {
        "backfill_\(sourceType.rawValue)_\(account.rawValue)_\(sourceId)"
    }
}

private struct FinanceHistoryBackfillPlan {
    let missingEntries: [FinanceExpectedJournalEntry]
    let materializationScopes: Set<BalanceScope>
}

private struct FinanceExpectedJournalEntry {
    let entry: JournalEntryModel
    let matchKey: MatchKey

    init(entry: JournalEntryModel, calendar: Calendar) {
        self.entry = entry
        self.matchKey = MatchKey(entry: entry, calendar: calendar)
    }

    struct MatchKey: Hashable {
        let sourceType: JournalSourceType
        let sourceId: String
        let account: PaymentAccount
        let normalizedDate: Date
        let amountInMinorUnits: Int64

        init(entry: JournalEntryModel, calendar: Calendar = .current) {
            self.sourceType = entry.sourceType
            self.sourceId = entry.sourceId
            self.account = entry.account
            self.normalizedDate = calendar.startOfDay(for: entry.date)
            self.amountInMinorUnits = Int64((entry.amount * 100).rounded())
        }
    }
}

extension BinaryFloatingPoint {
    fileprivate var isEffectivelyZero: Bool {
        abs(self) < 0.000_1
    }
}

extension FinanceHistorySourceFetching {
    fileprivate func fetchOrdersAsync() async -> [OrderModel] {
        await withCheckedContinuation { continuation in
            fetchOrders { continuation.resume(returning: $0) }
        }
    }

    fileprivate func fetchOpexExpensesAsync() async -> [OpexExpenseModel] {
        await withCheckedContinuation { continuation in
            fetchOpexExpenses { continuation.resume(returning: $0) }
        }
    }

    fileprivate func fetchPurchasesAsync() async -> [PurchaseModel] {
        await withCheckedContinuation { continuation in
            fetchPurchases { continuation.resume(returning: $0) }
        }
    }
}
