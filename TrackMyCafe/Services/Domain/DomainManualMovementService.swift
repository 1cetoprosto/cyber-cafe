import Foundation

struct ManualMovementOperation: Identifiable, Equatable {
    let id: String
    let date: Date
    let kind: ManualMovementKind
    let amount: Double
    let fromAccount: PaymentAccount?
    let toAccount: PaymentAccount?
    let note: String?
}

protocol ManualMovementServiceProtocol {
    func fetchOperations() async -> [ManualMovementOperation]
    func saveOperation(_ operation: ManualMovementOperation) async throws
    func deleteOperation(id: String) async throws
}

final class DomainManualMovementService: ManualMovementServiceProtocol, Loggable {
    private let database: FinancePersistenceProtocol
    private let balanceJournalService: BalanceJournalServiceProtocol
    private let dailyBalanceMaterializer: DailyBalanceMaterializerProtocol

    init(
        database: FinancePersistenceProtocol = DomainDatabaseService.shared,
        balanceJournalService: BalanceJournalServiceProtocol? = nil,
        dailyBalanceMaterializer: DailyBalanceMaterializerProtocol? = nil
    ) {
        self.database = database
        self.balanceJournalService = balanceJournalService ?? BalanceJournalService(database: database)
        self.dailyBalanceMaterializer =
            dailyBalanceMaterializer ?? DailyBalanceMaterializer(database: database)
    }

    func fetchOperations() async -> [ManualMovementOperation] {
        let entries = await database.fetchJournalEntriesAsync()
            .filter { $0.sourceType == .manual }

        let grouped = Dictionary(grouping: entries, by: \.sourceId)
        let operations = grouped.compactMap { sourceId, items -> ManualMovementOperation? in
            let kind = items.compactMap(\.manualKind).last
            guard let kind else { return nil }

            let day = items.map { Calendar.current.startOfDay(for: $0.date) }.max() ?? Date()
            let note = items.compactMap { $0.note }.last(where: { note in
                let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.isEmpty && !trimmed.lowercased().hasPrefix("storno")
            })

            let netByAccount = Dictionary(grouping: items, by: \.account).mapValues { rows in
                rows.reduce(0) { $0 + $1.amount }
            }.filter { _, value in
                abs(value) >= 0.000_1
            }

            switch kind {
            case .transfer:
                let from = netByAccount.first(where: { $0.value < 0 })?.key
                let to = netByAccount.first(where: { $0.value > 0 })?.key
                let amount = abs(netByAccount.first(where: { $0.value > 0 })?.value ?? 0)
                guard amount >= 0.000_1 else { return nil }
                return ManualMovementOperation(
                    id: sourceId,
                    date: day,
                    kind: kind,
                    amount: amount,
                    fromAccount: from,
                    toAccount: to,
                    note: note
                )
            case .deposit:
                guard let (account, raw) = netByAccount.first else { return nil }
                let amount = abs(raw)
                guard amount >= 0.000_1 else { return nil }
                return ManualMovementOperation(
                    id: sourceId,
                    date: day,
                    kind: kind,
                    amount: amount,
                    fromAccount: nil,
                    toAccount: account,
                    note: note
                )
            case .withdrawal:
                guard let (account, raw) = netByAccount.first else { return nil }
                let amount = abs(raw)
                guard amount >= 0.000_1 else { return nil }
                return ManualMovementOperation(
                    id: sourceId,
                    date: day,
                    kind: kind,
                    amount: amount,
                    fromAccount: account,
                    toAccount: nil,
                    note: note
                )
            case .adjustment:
                guard let (account, raw) = netByAccount.first else { return nil }
                guard abs(raw) >= 0.000_1 else { return nil }
                return ManualMovementOperation(
                    id: sourceId,
                    date: day,
                    kind: kind,
                    amount: raw,
                    fromAccount: account,
                    toAccount: nil,
                    note: note
                )
            }
        }

        return operations.sorted { left, right in
            if left.date != right.date { return left.date > right.date }
            return left.id > right.id
        }
    }

    func saveOperation(_ operation: ManualMovementOperation) async throws {
        let newEntries = makeEntries(from: operation)
        let scopes = try await balanceJournalService.syncManual(
            sourceId: operation.id,
            newEntries: newEntries
        )
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
        logger.info("Saved manual movement: \(operation.id)")
    }

    func deleteOperation(id: String) async throws {
        let scopes = try await balanceJournalService.syncManual(sourceId: id, newEntries: [])
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
        logger.info("Deleted manual movement: \(id)")
    }

    private func makeEntries(from operation: ManualMovementOperation) -> [JournalEntryModel] {
        let date = operation.date
        let note = operation.note

        switch operation.kind {
        case .deposit:
            guard let to = operation.toAccount else { return [] }
            return [
                JournalEntryModel(
                    date: date,
                    account: to,
                    amount: abs(operation.amount),
                    sourceType: .manual,
                    sourceId: operation.id,
                    note: note,
                    manualKind: .deposit
                )
            ]
        case .withdrawal:
            guard let from = operation.fromAccount else { return [] }
            return [
                JournalEntryModel(
                    date: date,
                    account: from,
                    amount: -abs(operation.amount),
                    sourceType: .manual,
                    sourceId: operation.id,
                    note: note,
                    manualKind: .withdrawal
                )
            ]
        case .adjustment:
            guard let account = operation.fromAccount else { return [] }
            guard abs(operation.amount) >= 0.000_1 else { return [] }
            return [
                JournalEntryModel(
                    date: date,
                    account: account,
                    amount: operation.amount,
                    sourceType: .manual,
                    sourceId: operation.id,
                    note: note,
                    manualKind: .adjustment
                )
            ]
        case .transfer:
            guard
                let from = operation.fromAccount,
                let to = operation.toAccount,
                from != to
            else { return [] }

            let amount = abs(operation.amount)
            guard amount >= 0.000_1 else { return [] }

            return [
                JournalEntryModel(
                    date: date,
                    account: from,
                    amount: -amount,
                    sourceType: .manual,
                    sourceId: operation.id,
                    note: note,
                    manualKind: .transfer
                ),
                JournalEntryModel(
                    date: date,
                    account: to,
                    amount: amount,
                    sourceType: .manual,
                    sourceId: operation.id,
                    note: note,
                    manualKind: .transfer
                ),
            ]
        }
    }
}

