//
//  InventoryAdjustmentDetailViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import Foundation

struct InventoryAdjustmentDetailRow {
    let title: String
    let value: String
    let isNumeric: Bool
}

protocol InventoryAdjustmentDetailViewModelProtocol: AnyObject {
    var onDataUpdated: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }

    var ingredientName: String { get }
    var deltaText: String { get }
    var deltaIsPositive: Bool { get }
    var rows: [InventoryAdjustmentDetailRow] { get }

    func loadData()
}

final class InventoryAdjustmentDetailViewModel: InventoryAdjustmentDetailViewModelProtocol {

    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    private(set) var ingredientName: String = ""
    private(set) var deltaText: String = ""
    private(set) var deltaIsPositive: Bool = true
    private(set) var rows: [InventoryAdjustmentDetailRow] = []

    private let adjustment: InventoryAdjustmentModel
    private let ingredientDataService: IngredientDataServiceProtocol

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .long
        return df
    }()

    init(
        adjustment: InventoryAdjustmentModel,
        ingredientDataService: IngredientDataServiceProtocol = DomainIngredientDataService.shared
    ) {
        self.adjustment = adjustment
        self.ingredientDataService = ingredientDataService
    }

    func loadData() {
        Task {
            do {
                let ingredients = try await ingredientDataService.fetchIngredients()
                let ingredient = ingredients.first { $0.id == adjustment.ingredientId }

                await MainActor.run {
                    let ingredientName = ingredient?.name ?? R.string.global.inventoryUnknownIngredient()
                    let unitText = ingredient?.unit.localizedName ?? ""

                    self.ingredientName = ingredientName
                    let delta = adjustment.quantityDelta
                    self.deltaIsPositive = delta >= 0
                    self.deltaText = InventoryAdjustmentListViewModel.formatDelta(delta, unit: unitText)

                    var rows: [InventoryAdjustmentDetailRow] = []

                    rows.append(
                        InventoryAdjustmentDetailRow(
                            title: R.string.global.inventoryAdjustmentDate(),
                            value: dateFormatter.string(from: adjustment.date),
                            isNumeric: false
                        )
                    )

                    rows.append(
                        InventoryAdjustmentDetailRow(
                            title: R.string.global.inventoryAdjustmentIngredient(),
                            value: ingredientName,
                            isNumeric: false
                        )
                    )

                    rows.append(
                        InventoryAdjustmentDetailRow(
                            title: R.string.global.inventoryAdjustmentDelta(),
                            value: self.deltaText,
                            isNumeric: true
                        )
                    )

                    if let expected = ingredient?.stockQuantity {
                        let before = expected - delta
                        let after = expected
                        rows.append(
                            InventoryAdjustmentDetailRow(
                                title: R.string.global.inventoryAdjustmentStockBefore(),
                                value: String(format: "%.2f %@", before, unitText),
                                isNumeric: true
                            )
                        )
                        rows.append(
                            InventoryAdjustmentDetailRow(
                                title: R.string.global.inventoryAdjustmentStockAfter(),
                                value: String(format: "%.2f %@", after, unitText),
                                isNumeric: true
                            )
                        )
                    }

                    rows.append(
                        InventoryAdjustmentDetailRow(
                            title: R.string.global.inventoryAdjustmentSource(),
                            value: adjustment.source.displayName,
                            isNumeric: false
                        )
                    )

                    if let sessionId = adjustment.bulkSessionId, !sessionId.isEmpty {
                        rows.append(
                            InventoryAdjustmentDetailRow(
                                title: R.string.global.inventoryAdjustmentBulkSession(),
                                value: sessionId,
                                isNumeric: false
                            )
                        )
                    }

                    if let userId = adjustment.userId, !userId.isEmpty {
                        rows.append(
                            InventoryAdjustmentDetailRow(
                                title: R.string.global.inventoryAdjustmentUser(),
                                value: userId,
                                isNumeric: false
                            )
                        )
                    }

                    if let reason = adjustment.reason, !reason.isEmpty {
                        rows.append(
                            InventoryAdjustmentDetailRow(
                                title: R.string.global.inventoryAdjustmentReason(),
                                value: reason,
                                isNumeric: false
                            )
                        )
                    }

                    self.rows = rows
                    self.onDataUpdated?()
                }
            } catch {
                await MainActor.run {
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
}
