//
//  BulkSessionViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import Foundation

struct BulkSessionRowViewModel: Identifiable {
    let id: String
    let ingredientId: String
    let name: String
    let unitText: String
    let expectedText: String
    var countedText: String?
    var deltaText: String?
    var deltaIsPositive: Bool?
}

protocol BulkSessionViewModelProtocol: AnyObject {
    var onDataUpdated: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var isLoading: ((Bool) -> Void)? { get set }
    var onFinished: (() -> Void)? { get set }

    var titleText: String { get }
    var sessionNote: String { get set }
    var items: [BulkSessionRowViewModel] { get }
    var summaryText: String { get }
    var canCommit: Bool { get }

    func startSession()
    func updateCounted(forRowAt index: Int, countedText: String?)
    func commitSession()
    func cancelSession()
}

final class BulkSessionViewModel: BulkSessionViewModelProtocol {

    // MARK: - Hooks

    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var isLoading: ((Bool) -> Void)?
    var onFinished: (() -> Void)?

    // MARK: - Output

    let titleText: String = R.string.global.inventoryBulkSessionTitle()
    var sessionNote: String = "" {
        didSet {
            onDataUpdated?()
        }
    }

    private(set) var items: [BulkSessionRowViewModel] = []
    private(set) var summaryText: String = ""
    private(set) var canCommit: Bool = false

    // MARK: - State

    private var session: InventoryBulkSession?
    private let auditService: InventoryAuditServiceProtocol
    private let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 3
        nf.minimumFractionDigits = 0
        return nf
    }()

    private let format: (Double) -> String = { value in
        String(format: "%.2f", value)
    }

    init(
        auditService: InventoryAuditServiceProtocol = InventoryAuditService.shared
    ) {
        self.auditService = auditService
    }

    // MARK: - Session lifecycle

    func startSession() {
        isLoading?(true)
        Task {
            do {
                let session = try await auditService.startBulkSession(includeAllIngredients: true)
                await MainActor.run {
                    self.session = session
                    self.items = session.items.map { self.makeRow(from: $0) }
                    self.updateSummary()
                    self.isLoading?(false)
                    self.onDataUpdated?()
                }
            } catch {
                await MainActor.run {
                    self.isLoading?(false)
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    func updateCounted(forRowAt index: Int, countedText: String?) {
        guard index < items.count else { return }
        guard var session else { return }

        let normalized = (countedText ?? "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var row = items[index]
        var sessionItem = session.items[index]

        if normalized.isEmpty {
            sessionItem.countedQuantity = nil
            row.countedText = nil
            row.deltaText = nil
            row.deltaIsPositive = nil
        } else if let number = Double(normalized) {
            sessionItem.countedQuantity = number
            row.countedText = format(number)
            let delta = number - sessionItem.expectedQuantity
            if delta == 0 {
                row.deltaText = "0 \(row.unitText)"
                row.deltaIsPositive = nil
            } else {
                row.deltaText = InventoryAdjustmentListViewModel.formatDelta(delta, unit: row.unitText)
                row.deltaIsPositive = delta > 0
            }
        } else {
            return
        }

        session.items[index] = sessionItem
        self.session = session
        items[index] = row
        updateSummary()
        onDataUpdated?()
    }

    func commitSession() {
        guard var session else { return }
        guard canCommit else { return }

        isLoading?(true)
        Task {
            do {
                _ = try await auditService.commitBulkSession(session, reason: sessionNote)
                await MainActor.run {
                    self.isLoading?(false)
                    self.onFinished?()
                }
            } catch {
                await MainActor.run {
                    self.isLoading?(false)
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    func cancelSession() {
        onFinished?()
    }

    // MARK: - Private

    private func makeRow(from item: InventoryBulkSessionItem) -> BulkSessionRowViewModel {
        let unit = item.ingredient.unit.localizedName
        return BulkSessionRowViewModel(
            id: item.id,
            ingredientId: item.ingredient.id,
            name: item.ingredient.name,
            unitText: unit,
            expectedText: String(format: "%@ %@", format(item.expectedQuantity), unit),
            countedText: nil,
            deltaText: nil,
            deltaIsPositive: nil
        )
    }

    private func updateSummary() {
        let countedCount = items.filter { $0.countedText != nil }.count
        let totalCount = items.count

        var deltaCount = 0
        var deltaSum: Double = 0
        for (index, row) in items.enumerated() {
            guard let session else { continue }
            guard let counted = session.items[index].countedQuantity else { continue }
            let delta = counted - session.items[index].expectedQuantity
            if delta != 0 {
                deltaCount += 1
                deltaSum += delta
            }
        }

        let countedPart = String(
            format: R.string.global.inventoryBulkSummaryCounted(countedCount, totalCount),
            countedCount, totalCount
        )
        let changesPart = String(
            format: R.string.global.inventoryBulkSummaryChanges(deltaCount),
            deltaCount
        )
        summaryText = "\(countedPart) • \(changesPart)"

        let noteValid = !sessionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        canCommit = noteValid && countedCount > 0
    }
}
