//
//  InventorySessionListViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 26.08.2026.
//

import Foundation

struct InventorySessionViewModel: Identifiable {
    let id: String
    let dateText: String
    let noteText: String
    let summaryText: String
    let adjustedCount: Int
}

protocol InventorySessionListViewModelProtocol: AnyObject {
    var onDataUpdated: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var isLoading: ((Bool) -> Void)? { get set }

    var items: [InventorySessionViewModel] { get }

    func sessionId(at indexPath: IndexPath) -> String?

    func fetchData()
}

final class InventorySessionListViewModel: InventorySessionListViewModelProtocol {

    // MARK: - Hooks

    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var isLoading: ((Bool) -> Void)?

    // MARK: - Output

    private(set) var items: [InventorySessionViewModel] = []

    // MARK: - State

    private var rawSessions: [(id: String, adjustments: [InventoryAdjustmentModel])] = []

    // MARK: - Dependencies

    private let auditService: InventoryAuditServiceProtocol

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    init(auditService: InventoryAuditServiceProtocol = InventoryAuditService.shared) {
        self.auditService = auditService
    }

    // MARK: - Fetch

    func fetchData() {
        isLoading?(true)
        Task {
            do {
                let all = try await auditService.fetchAdjustments(
                    from: nil,
                    to: nil,
                    ingredientId: nil,
                    bulkSessionId: nil
                )

                let grouped: [String: [InventoryAdjustmentModel]] = Dictionary(
                    grouping: all.filter { $0.bulkSessionId != nil }
                ) { $0.bulkSessionId ?? "" }

                let sessions: [(id: String, adjustments: [InventoryAdjustmentModel])] =
                    grouped
                    .map { (id: $0.key, adjustments: $0.value) }
                    .sorted { lhs, rhs in
                        let lhsMin = lhs.adjustments.map(\.date).min() ?? Date.distantPast
                        let rhsMin = rhs.adjustments.map(\.date).min() ?? Date.distantPast
                        return lhsMin > rhsMin
                    }

                let viewModels = sessions.map { sess -> InventorySessionViewModel in
                    let firstDate = sess.adjustments.map(\.date).min() ?? Date()
                    let note = sess.adjustments.first?.reason ?? ""
                    let count = sess.adjustments.count
                    return InventorySessionViewModel(
                        id: sess.id,
                        dateText: dateFormatter.string(from: firstDate),
                        noteText: note,
                        summaryText: String(
                            format: R.string.global.inventorySessionCountIngredients(count), count),
                        adjustedCount: count
                    )
                }

                await MainActor.run {
                    self.rawSessions = sessions
                    self.items = viewModels
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

    // MARK: - Accessors

    func sessionId(at indexPath: IndexPath) -> String? {
        guard indexPath.row < items.count else { return nil }
        return items[indexPath.row].id
    }
}
