//
//  InventoryService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation
import os.log

protocol InventoryServiceProtocol {
    func processPurchase(purchase: PurchaseModel) async throws
    func editPurchase(oldPurchase: PurchaseModel, newPurchase: PurchaseModel) async throws
    func processStockAdjustment(adjustment: InventoryAdjustmentModel) async throws
    func validateStockAvailability(for items: [OrderItemModel]) async -> [StockWarning]
    func validateStockAvailability(
        for items: [OrderItemModel],
        trackingEnabled: Bool
    ) async -> [StockWarning]
    func deductStock(for items: [OrderItemModel]) async throws
    func deductStock(
        for items: [OrderItemModel],
        trackingEnabled: Bool
    ) async throws
    func restoreStock(
        for items: [OrderItemModel],
        trackingEnabled: Bool
    ) async throws
}

struct StockWarning {
    let ingredientId: String
    let ingredientName: String
    let requiredQty: Double
    let currentStock: Double
}

final class InventoryService: InventoryServiceProtocol {
    static let shared = InventoryService()
    private let databaseService: DomainDB
    private let balanceJournalService: BalanceJournalServiceProtocol
    private let dailyBalanceMaterializer: DailyBalanceMaterializerProtocol
    private let settingsManager: SettingsManager
    private let logger = Logger(subsystem: "com.trackmycafe", category: "InventoryService")

    private init(
        databaseService: DomainDB = DomainDatabaseService.shared,
        balanceJournalService: BalanceJournalServiceProtocol = BalanceJournalService(),
        dailyBalanceMaterializer: DailyBalanceMaterializerProtocol = DailyBalanceMaterializer(),
        settingsManager: SettingsManager = .shared
    ) {
        self.databaseService = databaseService
        self.balanceJournalService = balanceJournalService
        self.dailyBalanceMaterializer = dailyBalanceMaterializer
        self.settingsManager = settingsManager
    }

    // MARK: - Purchase Processing

    func processPurchase(purchase: PurchaseModel) async throws {
        guard var ingredient = await databaseService.fetchIngredient(byId: purchase.ingredientId)
        else {
            throw NSError(
                domain: "InventoryService", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Ingredient not found"])
        }

        let oldTotalValue = ingredient.stockQuantity * ingredient.averageCost
        let newPurchaseValue = purchase.quantity * purchase.price
        let newTotalQuantity = ingredient.stockQuantity + purchase.quantity

        let newAverageCost: Double
        if newTotalQuantity > 0 {
            newAverageCost = (oldTotalValue + newPurchaseValue) / newTotalQuantity
        } else {
            newAverageCost = purchase.price
        }

        ingredient.stockQuantity = newTotalQuantity
        ingredient.averageCost = newAverageCost

        guard await databaseService.saveIngredient(model: ingredient) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to save ingredient"])
        }

        guard await databaseService.savePurchase(model: purchase) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to save purchase history"])
        }

        try await syncPurchaseBalance(previous: nil, current: purchase)
        logger.info("Processed purchase for ingredient: \(purchase.ingredientId)")
    }

    // MARK: - Purchase Editing

    func editPurchase(oldPurchase: PurchaseModel, newPurchase: PurchaseModel) async throws {
        if oldPurchase.ingredientId == newPurchase.ingredientId {
            try await editSameIngredient(oldPurchase: oldPurchase, newPurchase: newPurchase)
        } else {
            try await editDifferentIngredient(oldPurchase: oldPurchase, newPurchase: newPurchase)
        }
    }

    private func editSameIngredient(
        oldPurchase: PurchaseModel, newPurchase: PurchaseModel
    ) async throws {
        guard
            var ingredient = await databaseService.fetchIngredient(
                byId: oldPurchase.ingredientId)
        else {
            throw NSError(
                domain: "InventoryService", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Ingredient not found"])
        }

        let currentTotalValue = ingredient.stockQuantity * ingredient.averageCost
        let oldPurchaseValue = oldPurchase.quantity * oldPurchase.price
        let newPurchaseValue = newPurchase.quantity * newPurchase.price

        let finalTotalValue = currentTotalValue - oldPurchaseValue + newPurchaseValue
        let finalStock = ingredient.stockQuantity - oldPurchase.quantity + newPurchase.quantity

        let finalAverageCost: Double
        if finalStock > 0 {
            finalAverageCost = finalTotalValue / finalStock
        } else {
            finalAverageCost = newPurchase.price
        }

        ingredient.stockQuantity = finalStock
        ingredient.averageCost = finalAverageCost

        guard await databaseService.saveIngredient(model: ingredient) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to save ingredient"])
        }

        guard await databaseService.savePurchase(model: newPurchase) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to save purchase history"])
        }

        try await syncPurchaseBalance(previous: oldPurchase, current: newPurchase)
    }

    private func editDifferentIngredient(
        oldPurchase: PurchaseModel, newPurchase: PurchaseModel
    ) async throws {
        guard
            var oldIngredient = await databaseService.fetchIngredient(
                byId: oldPurchase.ingredientId)
        else {
            throw NSError(
                domain: "InventoryService", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Old ingredient not found"])
        }

        let currentTotalValue = oldIngredient.stockQuantity * oldIngredient.averageCost
        let oldPurchaseValue = oldPurchase.quantity * oldPurchase.price

        let revertedTotalValue = currentTotalValue - oldPurchaseValue
        let revertedStock = oldIngredient.stockQuantity - oldPurchase.quantity

        let revertedAvg: Double
        if revertedStock > 0 {
            revertedAvg = revertedTotalValue / revertedStock
        } else {
            revertedAvg = oldIngredient.averageCost
        }

        oldIngredient.stockQuantity = revertedStock
        oldIngredient.averageCost = revertedAvg

        guard await databaseService.saveIngredient(model: oldIngredient) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to revert old ingredient"])
        }

        try await processPurchase(purchase: newPurchase)
    }

    // MARK: - Stock Adjustment

    func processStockAdjustment(adjustment: InventoryAdjustmentModel) async throws {
        guard
            var ingredient = await databaseService.fetchIngredient(
                byId: adjustment.ingredientId)
        else {
            throw NSError(
                domain: "InventoryService", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Ingredient not found"])
        }

        ingredient.stockQuantity += adjustment.quantityDelta

        guard await databaseService.saveIngredient(model: ingredient) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to save ingredient"])
        }

        let adjId = await databaseService.saveInventoryAdjustment(model: adjustment)
        guard adjId != nil else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to save adjustment record"])
        }
        logger.info("Processed stock adjustment for ingredient: \(adjustment.ingredientId)")
    }

    // MARK: - Stock Deduction

    func deductStock(for items: [OrderItemModel]) async throws {
        try await deductStock(
            for: items,
            trackingEnabled: settingsManager.loadTrackIngredients()
        )
    }

    func deductStock(
        for items: [OrderItemModel],
        trackingEnabled: Bool
    ) async throws {
        guard trackingEnabled else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask {
                    try await self.deductStock(for: item)
                }
            }
            try await group.waitForAll()
        }
    }

    private func deductStock(for item: OrderItemModel) async throws {
        let recipeItems = await databaseService.fetchRecipe(forProductId: item.productId)
        guard !recipeItems.isEmpty else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for recipeItem in recipeItems {
                group.addTask {
                    try await self.deductRecipeItem(recipeItem, quantity: item.quantity)
                }
            }
            try await group.waitForAll()
        }
    }

    private func deductRecipeItem(_ recipeItem: RecipeItemModel, quantity: Int) async throws {
        guard
            var ingredient = await databaseService.fetchIngredient(
                byId: recipeItem.ingredientId)
        else { return }

        let deductionAmount = recipeItem.quantity * Double(quantity)
        ingredient.stockQuantity -= deductionAmount

        guard await databaseService.saveIngredient(model: ingredient) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to save ingredient \(ingredient.name)"
                ])
        }
    }

    func restoreStock(
        for items: [OrderItemModel],
        trackingEnabled: Bool
    ) async throws {
        guard trackingEnabled else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask {
                    try await self.restoreStock(for: item)
                }
            }
            try await group.waitForAll()
        }
    }

    private func restoreStock(for item: OrderItemModel) async throws {
        let recipeItems = await databaseService.fetchRecipe(forProductId: item.productId)
        guard !recipeItems.isEmpty else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for recipeItem in recipeItems {
                group.addTask {
                    try await self.restoreRecipeItem(recipeItem, quantity: item.quantity)
                }
            }
            try await group.waitForAll()
        }
    }

    private func restoreRecipeItem(_ recipeItem: RecipeItemModel, quantity: Int) async throws {
        guard
            var ingredient = await databaseService.fetchIngredient(
                byId: recipeItem.ingredientId)
        else { return }

        let restoreAmount = recipeItem.quantity * Double(quantity)
        ingredient.stockQuantity += restoreAmount

        guard await databaseService.saveIngredient(model: ingredient) else {
            throw NSError(
                domain: "InventoryService", code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to save ingredient \(ingredient.name)"
                ])
        }
    }

    // MARK: - Validation

    func validateStockAvailability(for items: [OrderItemModel]) async -> [StockWarning] {
        await validateStockAvailability(
            for: items,
            trackingEnabled: settingsManager.loadTrackIngredients()
        )
    }

    func validateStockAvailability(
        for items: [OrderItemModel],
        trackingEnabled: Bool
    ) async -> [StockWarning] {
        guard trackingEnabled else { return [] }

        var requiredIngredients: [String: Double] = [:]

        await withTaskGroup(of: [String: Double].self) { group in
            for item in items {
                group.addTask {
                    let recipeItems = await self.databaseService.fetchRecipe(
                        forProductId: item.productId)
                    var requirements: [String: Double] = [:]
                    for recipeItem in recipeItems {
                        let totalRequired = recipeItem.quantity * Double(item.quantity)
                        requirements[recipeItem.ingredientId, default: 0] += totalRequired
                    }
                    return requirements
                }
            }

            for await requirements in group {
                for (ingredientId, qty) in requirements {
                    requiredIngredients[ingredientId, default: 0] += qty
                }
            }
        }

        return await withTaskGroup(of: StockWarning?.self) { group in
            for (ingredientId, requiredQty) in requiredIngredients {
                group.addTask {
                    guard
                        let ingredient = await self.databaseService.fetchIngredient(
                            byId: ingredientId)
                    else { return nil }
                    if ingredient.stockQuantity < requiredQty {
                        return StockWarning(
                            ingredientId: ingredientId,
                            ingredientName: ingredient.name,
                            requiredQty: requiredQty,
                            currentStock: ingredient.stockQuantity
                        )
                    }
                    return nil
                }
            }

            var warnings: [StockWarning] = []
            for await warning in group {
                if let warning = warning {
                    warnings.append(warning)
                }
            }
            return warnings
        }
    }

    // MARK: - Balance Sync

    private func syncPurchaseBalance(
        previous: PurchaseModel?,
        current: PurchaseModel?
    ) async throws {
        let scopes = try await balanceJournalService.syncPurchase(
            previous: previous,
            current: current
        )
        try await dailyBalanceMaterializer.materialize(scopes: scopes)
    }
}
