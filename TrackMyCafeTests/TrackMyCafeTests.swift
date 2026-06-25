import XCTest

@testable import TrackMyCafe_Dev

final class TrackMyCafeTests: XCTestCase {
    func testBalanceJournalService_orderCreate_appendsCashAndCardEntries() async throws {
        let persistence = MockFinancePersistence()
        let service = BalanceJournalService(database: persistence)
        let date = makeDate(year: 2026, month: 6, day: 22)
        let order = OrderModel(
            id: "order-1",
            date: date,
            type: "Hall",
            sum: 150,
            cash: 100,
            card: 50,
            totalCost: 60,
            note: "Test"
        )

        let scopes = try await service.syncOrder(previous: nil, current: order)

        XCTAssertEqual(persistence.savedJournalEntries.count, 2)
        XCTAssertEqual(
            Set(persistence.savedJournalEntries.map { JournalEntrySnapshot(entry: $0) }),
            Set([
                JournalEntrySnapshot(account: .cash, amount: 100),
                JournalEntrySnapshot(account: .card, amount: 50),
            ])
        )
        XCTAssertEqual(
            scopes,
            Set([
                BalanceScope(account: .cash, date: date),
                BalanceScope(account: .card, date: date),
            ])
        )
    }

    func testBalanceJournalService_orderUpdate_appendsStornoAndNewEntries() async throws {
        let persistence = MockFinancePersistence()
        let service = BalanceJournalService(database: persistence)
        let date = makeDate(year: 2026, month: 6, day: 22)
        let previous = OrderModel(
            id: "order-1",
            date: date,
            type: "Hall",
            sum: 150,
            cash: 100,
            card: 50,
            totalCost: 60,
            note: "Before"
        )
        let current = OrderModel(
            id: "order-1",
            date: date,
            type: "Hall",
            sum: 150,
            cash: 70,
            card: 80,
            totalCost: 60,
            note: "After"
        )
        persistence.journalEntries = [
            JournalEntryModel(
                date: date,
                account: .cash,
                amount: 100,
                sourceType: .order,
                sourceId: "order-1",
                note: "Before"
            ),
            JournalEntryModel(
                date: date,
                account: .card,
                amount: 50,
                sourceType: .order,
                sourceId: "order-1",
                note: "Before"
            ),
        ]

        _ = try await service.syncOrder(previous: previous, current: current)

        XCTAssertEqual(persistence.savedJournalEntries.count, 4)
        XCTAssertEqual(
            Set(persistence.savedJournalEntries.map { JournalEntrySnapshot(entry: $0) }),
            Set([
                JournalEntrySnapshot(account: .cash, amount: -100),
                JournalEntrySnapshot(account: .card, amount: -50),
                JournalEntrySnapshot(account: .cash, amount: 70),
                JournalEntrySnapshot(account: .card, amount: 80),
            ])
        )
    }

    func testBalanceJournalService_legacyOpexWithoutPaymentAccount_doesNotAppendEntries()
        async throws
    {
        let persistence = MockFinancePersistence()
        let service = BalanceJournalService(database: persistence)
        let expense = OpexExpenseModel(
            id: "opex-1",
            date: makeDate(year: 2026, month: 6, day: 22),
            categoryId: "General",
            amount: 40,
            paymentAccount: nil,
            note: "Legacy"
        )

        let scopes = try await service.syncOpex(previous: nil, current: expense)

        XCTAssertTrue(persistence.savedJournalEntries.isEmpty)
        XCTAssertTrue(scopes.isEmpty)
    }

    func testBalanceJournalService_purchaseCreate_appendsExpenseEntry() async throws {
        let persistence = MockFinancePersistence()
        let service = BalanceJournalService(database: persistence)
        let purchase = PurchaseModel(
            id: "purchase-1",
            date: makeDate(year: 2026, month: 6, day: 22),
            ingredientId: "ingredient-1",
            quantity: 4,
            price: 25,
            paymentAccount: .card
        )

        let scopes = try await service.syncPurchase(previous: nil, current: purchase)

        XCTAssertEqual(persistence.savedJournalEntries.count, 1)
        XCTAssertEqual(persistence.savedJournalEntries.first?.account, .card)
        XCTAssertEqual(persistence.savedJournalEntries.first?.amount, -100)
        XCTAssertEqual(
            scopes,
            [BalanceScope(account: .card, date: purchase.date)]
        )
    }

    func testBalanceJournalService_purchaseUsesStoredTotalAmount() async throws {
        let persistence = MockFinancePersistence()
        let service = BalanceJournalService(database: persistence)
        let purchase = PurchaseModel(
            id: "purchase-stored-total",
            date: makeDate(year: 2026, month: 6, day: 22),
            ingredientId: "ingredient-1",
            quantity: 4,
            price: 25,
            totalAmount: 111,
            paymentAccount: .cash
        )

        _ = try await service.syncPurchase(previous: nil, current: purchase)

        XCTAssertEqual(persistence.savedJournalEntries.count, 1)
        XCTAssertEqual(persistence.savedJournalEntries.first?.amount, -111)
    }

    func testBalanceJournalService_legacyPurchaseWithoutPaymentAccount_doesNotAppendEntries()
        async throws
    {
        let persistence = MockFinancePersistence()
        let service = BalanceJournalService(database: persistence)
        let purchase = PurchaseModel(
            id: "purchase-legacy",
            date: makeDate(year: 2026, month: 6, day: 22),
            ingredientId: "ingredient-1",
            quantity: 2,
            price: 15
        )

        let scopes = try await service.syncPurchase(previous: nil, current: purchase)

        XCTAssertTrue(persistence.savedJournalEntries.isEmpty)
        XCTAssertTrue(scopes.isEmpty)
    }

    func testDailyBalanceMaterializer_buildsCumulativeBalances() async throws {
        let persistence = MockFinancePersistence()
        let service = DailyBalanceMaterializer(database: persistence)
        let dayOne = makeDate(year: 2026, month: 6, day: 21)
        let dayTwo = makeDate(year: 2026, month: 6, day: 22)
        persistence.journalEntries = [
            JournalEntryModel(
                date: dayOne,
                account: .cash,
                amount: 100,
                sourceType: .order,
                sourceId: "order-1"
            ),
            JournalEntryModel(
                date: dayTwo,
                account: .cash,
                amount: 50,
                sourceType: .order,
                sourceId: "order-2"
            ),
        ]

        try await service.materialize(
            scopes: [BalanceScope(account: .cash, date: dayOne)]
        )

        XCTAssertEqual(persistence.savedDailyBalances.count, 2)
        XCTAssertTrue(
            Calendar.current.isDate(persistence.savedDailyBalances[0].date, inSameDayAs: dayOne)
        )
        XCTAssertEqual(persistence.savedDailyBalances[0].delta, 100)
        XCTAssertEqual(persistence.savedDailyBalances[0].balance, 100)
        XCTAssertTrue(
            Calendar.current.isDate(persistence.savedDailyBalances[1].date, inSameDayAs: dayTwo)
        )
        XCTAssertEqual(persistence.savedDailyBalances[1].delta, 50)
        XCTAssertEqual(persistence.savedDailyBalances[1].balance, 150)
    }

    func testDailyBalanceMaterializer_deletesExistingDayWhenDeltaBecomesZero() async throws {
        let persistence = MockFinancePersistence()
        let service = DailyBalanceMaterializer(database: persistence)
        let date = makeDate(year: 2026, month: 6, day: 22)
        persistence.dailyBalancesByAccount[.cash] = [
            DailyBalanceModel(
                id: DailyBalanceModel.makeDocumentId(for: .cash, date: date),
                date: date,
                account: .cash,
                balance: 100,
                delta: 100
            )
        ]

        try await service.materialize(
            scopes: [BalanceScope(account: .cash, date: date)]
        )

        XCTAssertTrue(persistence.savedDailyBalances.isEmpty)
        XCTAssertEqual(
            persistence.deletedDocuments,
            [
                DeletedDocument(
                    collection: FirebaseCollections.dailyBalances,
                    documentId: DailyBalanceModel.makeDocumentId(for: .cash, date: date)
                )
            ]
        )
    }

    func testDomainCostDataService_saveCost_usesPersistedIdentifierForJournalSync() async throws {
        let persistence = MockFinancePersistence()
        persistence.nextSavedOpexId = "firestore-opex-id"
        let journalService = MockBalanceJournalService()
        let materializer = MockDailyBalanceMaterializer()
        let service = DomainCostDataService(
            database: persistence,
            balanceJournalService: journalService,
            dailyBalanceMaterializer: materializer
        )
        let cost = OpexExpenseModel(
            id: "temp-id",
            date: makeDate(year: 2026, month: 6, day: 22),
            categoryId: "General",
            amount: 55,
            paymentAccount: .cash,
            note: "Opex"
        )
        let expectedScopes: Set<BalanceScope> = [BalanceScope(account: .cash, date: cost.date)]
        journalService.opexScopesToReturn = expectedScopes

        try await service.saveCost(cost)

        XCTAssertEqual(persistence.savedOpexModels.map(\.id), ["temp-id"])
        XCTAssertEqual(journalService.lastCurrentOpex?.id, "firestore-opex-id")
        XCTAssertEqual(materializer.receivedScopes, expectedScopes)
    }

    func testFinanceHistoryBackfillService_createsOnlyMissingEntriesAndMarksCompleted()
        async throws
    {
        let sourceFetcher = MockFinanceHistorySourceFetcher()
        let persistence = MockFinancePersistence()
        let materializer = MockDailyBalanceMaterializer()
        let defaults = makeUserDefaultsSuite()

        let dayOne = makeDate(year: 2026, month: 6, day: 20)
        let dayTwo = makeDate(year: 2026, month: 6, day: 21)
        let dayThree = makeDate(year: 2026, month: 6, day: 22)

        sourceFetcher.orders = [
            OrderModel(
                id: "order-1",
                date: dayOne,
                type: "Hall",
                sum: 150,
                cash: 100,
                card: 50,
                totalCost: 60,
                note: "Order"
            )
        ]
        sourceFetcher.expenses = [
            OpexExpenseModel(
                id: "opex-1",
                date: dayTwo,
                categoryId: "General",
                amount: 25,
                paymentAccount: .cash,
                note: "Beans"
            ),
            OpexExpenseModel(
                id: "opex-legacy",
                date: dayThree,
                categoryId: "General",
                amount: 11,
                paymentAccount: nil,
                note: "Legacy"
            ),
        ]
        sourceFetcher.purchases = [
            PurchaseModel(
                id: "purchase-1",
                date: dayThree,
                ingredientId: "ingredient-1",
                quantity: 2,
                price: 20,
                totalAmount: 40,
                paymentAccount: .card
            ),
            PurchaseModel(
                id: "purchase-legacy",
                date: dayThree,
                ingredientId: "ingredient-2",
                quantity: 1,
                price: 15,
                totalAmount: 15,
                paymentAccount: nil
            ),
        ]

        persistence.journalEntries = [
            JournalEntryModel(
                date: dayOne,
                account: .cash,
                amount: 100,
                sourceType: .order,
                sourceId: "order-1",
                note: "Old note"
            )
        ]

        let service = FinanceHistoryBackfillService(
            sourceFetcher: sourceFetcher,
            persistence: persistence,
            dailyBalanceMaterializer: materializer,
            userDefaults: defaults
        )

        let didRun = try await service.runIfNeeded()

        XCTAssertTrue(didRun)
        XCTAssertEqual(
            Set(persistence.savedJournalEntries.map { JournalEntrySnapshot(entry: $0) }),
            Set([
                JournalEntrySnapshot(account: .card, amount: 50),
                JournalEntrySnapshot(account: .cash, amount: -25),
                JournalEntrySnapshot(account: .card, amount: -40),
            ])
        )
        XCTAssertEqual(
            materializer.receivedScopes,
            Set([
                BalanceScope(account: .cash, date: dayOne),
                BalanceScope(account: .card, date: dayOne),
            ])
        )
        XCTAssertTrue(defaults.bool(forKey: UserDefaultsKeys.financeHistoryBackfillCompleted))
        XCTAssertNotNil(defaults.object(forKey: UserDefaultsKeys.financeHistoryBackfillCompletedAt))
    }

    func testFinanceHistoryBackfillService_existingEntriesDoNotDuplicateAndStillMaterialize()
        async throws
    {
        let sourceFetcher = MockFinanceHistorySourceFetcher()
        let persistence = MockFinancePersistence()
        let materializer = MockDailyBalanceMaterializer()
        let defaults = makeUserDefaultsSuite()
        let date = makeDate(year: 2026, month: 6, day: 22)

        sourceFetcher.orders = [
            OrderModel(
                id: "order-existing",
                date: date,
                type: "Hall",
                sum: 80,
                cash: 80,
                card: 0,
                totalCost: 25,
                note: "Current"
            )
        ]
        persistence.journalEntries = [
            JournalEntryModel(
                date: date,
                account: .cash,
                amount: 80,
                sourceType: .order,
                sourceId: "order-existing",
                note: "Previous note"
            )
        ]

        let service = FinanceHistoryBackfillService(
            sourceFetcher: sourceFetcher,
            persistence: persistence,
            dailyBalanceMaterializer: materializer,
            userDefaults: defaults
        )

        let didRun = try await service.runIfNeeded()

        XCTAssertTrue(didRun)
        XCTAssertTrue(persistence.savedJournalEntries.isEmpty)
        XCTAssertEqual(
            materializer.receivedScopes,
            [BalanceScope(account: .cash, date: date)]
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components) ?? Date()
    }

    private func makeUserDefaultsSuite() -> UserDefaults {
        let suiteName = "TrackMyCafeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class MockFinancePersistence: FinancePersistenceProtocol {
    var nextSavedOrderId = "saved-order-id"
    var nextSavedOpexId = "saved-opex-id"
    var journalEntries: [JournalEntryModel] = []
    var dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]] = [:]

    var savedJournalEntries: [JournalEntryModel] = []
    var savedDailyBalances: [DailyBalanceModel] = []
    var deletedDocuments: [DeletedDocument] = []
    var savedOpexModels: [OpexExpenseModel] = []

    func saveOrder(order: OrderModel, completion: @escaping (String?) -> Void) {
        completion(nextSavedOrderId)
    }

    func updateOrder(_ order: OrderModel, completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func deleteOrder(order: OrderModel, completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func saveOpexExpense(model: OpexExpenseModel, completion: @escaping (String?) -> Void) {
        savedOpexModels.append(model)
        completion(nextSavedOpexId)
    }

    func updateOpexExpense(model: OpexExpenseModel, completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func deleteOpexExpense(model: OpexExpenseModel, completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func saveJournalEntry(model: JournalEntryModel, completion: @escaping (String?) -> Void) {
        savedJournalEntries.append(model)
        completion(model.id)
    }

    func fetchJournalEntries(completion: @escaping ([JournalEntryModel]) -> Void) {
        completion(journalEntries)
    }

    func saveDailyBalance(model: DailyBalanceModel, completion: @escaping (Bool) -> Void) {
        savedDailyBalances.append(model)
        completion(true)
    }

    func fetchDailyBalances(
        forAccount account: PaymentAccount,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping ([DailyBalanceModel]) -> Void
    ) {
        let balances = dailyBalancesByAccount[account] ?? []
        completion(balances.filter { $0.date >= startDate && $0.date <= endDate })
    }

    func delete(collection: String, documentId: String, completion: @escaping (Bool) -> Void) {
        deletedDocuments.append(
            DeletedDocument(collection: collection, documentId: documentId)
        )
        completion(true)
    }
}

private struct JournalEntrySnapshot: Hashable {
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

private struct DeletedDocument: Equatable {
    let collection: String
    let documentId: String
}

private final class MockBalanceJournalService: BalanceJournalServiceProtocol {
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
}

private final class MockDailyBalanceMaterializer: DailyBalanceMaterializerProtocol {
    private(set) var receivedScopes: Set<BalanceScope> = []

    func materialize(scopes: Set<BalanceScope>) async throws {
        receivedScopes = scopes
    }
}

private final class MockFinanceHistorySourceFetcher: FinanceHistorySourceFetching {
    var orders: [OrderModel] = []
    var expenses: [OpexExpenseModel] = []
    var purchases: [PurchaseModel] = []

    func fetchOrders(completion: @escaping ([OrderModel]) -> Void) {
        completion(orders)
    }

    func fetchOpexExpenses(completion: @escaping ([OpexExpenseModel]) -> Void) {
        completion(expenses)
    }

    func fetchPurchases(completion: @escaping ([PurchaseModel]) -> Void) {
        completion(purchases)
    }
}
