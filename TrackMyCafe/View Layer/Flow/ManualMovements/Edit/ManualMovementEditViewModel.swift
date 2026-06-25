import Foundation

protocol ManualMovementEditViewModelType {
    var isEditing: Bool { get }
    var initialKind: ManualMovementKind { get }
    var initialDate: Date { get }
    var initialAmountText: String? { get }
    var initialFromAccount: PaymentAccount? { get }
    var initialToAccount: PaymentAccount? { get }
    var initialNote: String? { get }
    var initialAdjustmentIsNegative: Bool { get }

    func save(
        kind: ManualMovementKind,
        date: Date,
        amountText: String?,
        fromAccount: PaymentAccount?,
        toAccount: PaymentAccount?,
        note: String?,
        adjustmentIsNegative: Bool
    ) async throws
}

enum ManualMovementEditError: LocalizedError {
    case invalidAmount
    case missingAccount
    case invalidTransferAccounts

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return NSLocalizedString("fillAllFields", tableName: "Global", comment: "")
        case .missingAccount:
            return NSLocalizedString("fillAllFields", tableName: "Global", comment: "")
        case .invalidTransferAccounts:
            return NSLocalizedString("manualMovementInvalidTransfer", tableName: "Global", comment: "")
        }
    }
}

final class ManualMovementEditViewModel: ManualMovementEditViewModelType {
    private let service: ManualMovementServiceProtocol
    private let operationToEdit: ManualMovementOperation?
    private let operationId: String

    init(operationToEdit: ManualMovementOperation?, service: ManualMovementServiceProtocol) {
        self.operationToEdit = operationToEdit
        self.service = service
        self.operationId = operationToEdit?.id ?? UUID().uuidString
    }

    var isEditing: Bool { operationToEdit != nil }
    var initialKind: ManualMovementKind { operationToEdit?.kind ?? .deposit }
    var initialDate: Date { operationToEdit?.date ?? Date() }
    var initialAmountText: String? {
        guard let op = operationToEdit else { return nil }
        switch op.kind {
        case .adjustment:
            return abs(op.amount).decimalFormat
        default:
            return abs(op.amount).decimalFormat
        }
    }
    var initialFromAccount: PaymentAccount? { operationToEdit?.fromAccount ?? .cash }
    var initialToAccount: PaymentAccount? { operationToEdit?.toAccount ?? .card }
    var initialNote: String? { operationToEdit?.note }
    var initialAdjustmentIsNegative: Bool {
        guard let op = operationToEdit, op.kind == .adjustment else { return false }
        return op.amount < 0
    }

    func save(
        kind: ManualMovementKind,
        date: Date,
        amountText: String?,
        fromAccount: PaymentAccount?,
        toAccount: PaymentAccount?,
        note: String?,
        adjustmentIsNegative: Bool
    ) async throws {
        guard let amount = parsedAmount(from: amountText), amount >= 0.000_1 else {
            throw ManualMovementEditError.invalidAmount
        }

        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteToSave = (trimmedNote?.isEmpty == false) ? trimmedNote : nil

        let operation: ManualMovementOperation
        switch kind {
        case .deposit:
            guard let toAccount else { throw ManualMovementEditError.missingAccount }
            operation = ManualMovementOperation(
                id: operationId,
                date: date,
                kind: kind,
                amount: amount,
                fromAccount: nil,
                toAccount: toAccount,
                note: noteToSave
            )
        case .withdrawal:
            guard let fromAccount else { throw ManualMovementEditError.missingAccount }
            operation = ManualMovementOperation(
                id: operationId,
                date: date,
                kind: kind,
                amount: amount,
                fromAccount: fromAccount,
                toAccount: nil,
                note: noteToSave
            )
        case .adjustment:
            guard let fromAccount else { throw ManualMovementEditError.missingAccount }
            let signed = adjustmentIsNegative ? -amount : amount
            operation = ManualMovementOperation(
                id: operationId,
                date: date,
                kind: kind,
                amount: signed,
                fromAccount: fromAccount,
                toAccount: nil,
                note: noteToSave
            )
        case .transfer:
            guard let fromAccount, let toAccount else { throw ManualMovementEditError.missingAccount }
            guard fromAccount != toAccount else { throw ManualMovementEditError.invalidTransferAccounts }
            operation = ManualMovementOperation(
                id: operationId,
                date: date,
                kind: kind,
                amount: amount,
                fromAccount: fromAccount,
                toAccount: toAccount,
                note: noteToSave
            )
        }

        try await service.saveOperation(operation)
    }

    private func parsedAmount(from text: String?) -> Double? {
        guard let text = text, !text.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter.number(from: text)?.doubleValue ?? Double(text.replacingOccurrences(of: ",", with: "."))
    }
}

