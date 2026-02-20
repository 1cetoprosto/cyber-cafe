//
//  InventoryService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

protocol InventoryServiceProtocol {
    func processPurchase(
        purchase: PurchaseModel, completion: @escaping (Result<Void, Error>) -> Void)
    func editPurchase(
        oldPurchase: PurchaseModel, newPurchase: PurchaseModel,
        completion: @escaping (Result<Void, Error>) -> Void)
    func processStockAdjustment(
        adjustment: InventoryAdjustmentModel, completion: @escaping (Result<Void, Error>) -> Void)
    func validateStockAvailability(
        for items: [OrderItemModel], completion: @escaping ([StockWarning]) -> Void)
    func deductStock(
        for items: [OrderItemModel], completion: @escaping (Result<Void, Error>) -> Void)
}

struct StockWarning {
    let ingredientId: String
    let ingredientName: String
    let requiredQty: Double
    let currentStock: Double
}

class InventoryService: InventoryServiceProtocol {
    static let shared = InventoryService()
    private let databaseService = DomainDatabaseService.shared

    private init() {}

    // MARK: - Purchase Processing

    func processPurchase(
        purchase: PurchaseModel, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 1. Fetch current ingredient state
        databaseService.fetchIngredient(byId: purchase.ingredientId) { [weak self] ingredient in
            guard var ingredient = ingredient else {
                completion(
                    .failure(
                        NSError(
                            domain: "InventoryService", code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "Ingredient not found"])))
                return
            }

            // 2. Calculate new weighted average cost
            // Formula: ((OldQty * OldAvg) + (NewQty * NewPrice)) / (OldQty + NewQty)

            let oldTotalValue = ingredient.stockQuantity * ingredient.averageCost
            let newPurchaseValue = purchase.quantity * purchase.price
            let newTotalQuantity = ingredient.stockQuantity + purchase.quantity

            let newAverageCost: Double
            if newTotalQuantity > 0 {
                newAverageCost = (oldTotalValue + newPurchaseValue) / newTotalQuantity
            } else {
                newAverageCost = purchase.price  // Fallback if stock is 0 (shouldn't happen with purchase)
            }

            // 3. Update ingredient model
            ingredient.stockQuantity = newTotalQuantity
            ingredient.averageCost = newAverageCost

            // 4. Save updated ingredient
            self?.databaseService.saveIngredient(model: ingredient) { success in
                if success {
                    // 5. Save Purchase record to history
                    self?.databaseService.savePurchase(model: purchase) { purchaseSuccess in
                        if purchaseSuccess {
                            completion(.success(()))
                        } else {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "InventoryService", code: 500,
                                        userInfo: [
                                            NSLocalizedDescriptionKey:
                                                "Failed to save purchase history"
                                        ])))
                        }
                    }
                } else {
                    completion(
                        .failure(
                            NSError(
                                domain: "InventoryService", code: 500,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to save ingredient"]))
                    )
                }
            }
        }
    }

    // MARK: - Purchase Editing

    func editPurchase(
        oldPurchase: PurchaseModel, newPurchase: PurchaseModel,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        if oldPurchase.ingredientId == newPurchase.ingredientId {
            // Same Ingredient: Revert old and Apply new in one step
            databaseService.fetchIngredient(byId: oldPurchase.ingredientId) {
                [weak self] ingredient in
                guard var ingredient = ingredient else {
                    completion(
                        .failure(
                            NSError(
                                domain: "InventoryService", code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Ingredient not found"])))
                    return
                }

                let currentTotalValue = ingredient.stockQuantity * ingredient.averageCost
                let oldPurchaseValue = oldPurchase.quantity * oldPurchase.price
                let newPurchaseValue = newPurchase.quantity * newPurchase.price

                let finalTotalValue = currentTotalValue - oldPurchaseValue + newPurchaseValue
                let finalStock =
                    ingredient.stockQuantity - oldPurchase.quantity + newPurchase.quantity

                let finalAverageCost: Double
                if finalStock > 0 {
                    finalAverageCost = finalTotalValue / finalStock
                } else {
                    finalAverageCost = newPurchase.price
                }

                ingredient.stockQuantity = finalStock
                ingredient.averageCost = finalAverageCost

                self?.databaseService.saveIngredient(model: ingredient) { success in
                    if success {
                        self?.databaseService.savePurchase(model: newPurchase) { purchaseSuccess in
                            if purchaseSuccess {
                                completion(.success(()))
                            } else {
                                completion(
                                    .failure(
                                        NSError(
                                            domain: "InventoryService", code: 500,
                                            userInfo: [
                                                NSLocalizedDescriptionKey:
                                                    "Failed to save purchase history"
                                            ])))
                            }
                        }
                    } else {
                        completion(
                            .failure(
                                NSError(
                                    domain: "InventoryService", code: 500,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Failed to save ingredient"
                                    ])))
                    }
                }
            }
        } else {
            // Different Ingredient: Revert old, then Process new
            databaseService.fetchIngredient(byId: oldPurchase.ingredientId) {
                [weak self] oldIngredient in
                guard var oldIngredient = oldIngredient else {
                    completion(
                        .failure(
                            NSError(
                                domain: "InventoryService", code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Old ingredient not found"])))
                    return
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

                self?.databaseService.saveIngredient(model: oldIngredient) { success in
                    if success {
                        self?.processPurchase(purchase: newPurchase, completion: completion)
                    } else {
                        completion(
                            .failure(
                                NSError(
                                    domain: "InventoryService", code: 500,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Failed to revert old ingredient"
                                    ])))
                    }
                }
            }
        }
    }

    // MARK: - Stock Adjustment

    func processStockAdjustment(
        adjustment: InventoryAdjustmentModel, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Ensure we are on the main thread when fetching/updating Realm objects
        // to avoid "Realm accessed from incorrect thread" error
        DispatchQueue.main.async { [weak self] in
            self?.databaseService.fetchIngredient(byId: adjustment.ingredientId) { ingredient in
                guard var ingredient = ingredient else {
                    completion(
                        .failure(
                            NSError(
                                domain: "InventoryService", code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Ingredient not found"])))
                    return
                }

                // Adjust quantity ONLY. Average cost remains unchanged.
                ingredient.stockQuantity += adjustment.quantityDelta

                // Create a local copy for saving to avoid thread issues with reference types
                let ingredientToSave = ingredient

                self?.databaseService.saveIngredient(model: ingredientToSave) { success in
                    if success {
                        // TODO: Save Adjustment record (when DB supports it)
                        completion(.success(()))
                    } else {
                        completion(
                            .failure(
                                NSError(
                                    domain: "InventoryService", code: 500,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Failed to save ingredient"
                                    ]))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Stock Deduction

    func deductStock(
        for items: [OrderItemModel], completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let dispatchGroup = DispatchGroup()
        var errors: [Error] = []

        for item in items {
            dispatchGroup.enter()
            // 1. Get Recipe
            databaseService.fetchRecipe(forProductId: item.productId) { [weak self] recipeItems in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }

                if recipeItems.isEmpty {
                    dispatchGroup.leave()
                    return
                }

                let innerGroup = DispatchGroup()

                for recipeItem in recipeItems {
                    innerGroup.enter()
                    // 2. Fetch Ingredient
                    self.databaseService.fetchIngredient(byId: recipeItem.ingredientId) {
                        ingredient in
                        guard var ingredient = ingredient else {
                            innerGroup.leave()
                            return
                        }

                        // 3. Deduct Quantity
                        let deductionAmount = recipeItem.quantity * Double(item.quantity)
                        ingredient.stockQuantity -= deductionAmount

                        // 4. Save Ingredient
                        self.databaseService.saveIngredient(model: ingredient) { success in
                            if !success {
                                errors.append(
                                    NSError(
                                        domain: "InventoryService", code: 500,
                                        userInfo: [
                                            NSLocalizedDescriptionKey:
                                                "Failed to save ingredient \(ingredient.name)"
                                        ]))
                            }
                            innerGroup.leave()
                        }
                    }
                }

                innerGroup.notify(queue: .global()) {
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(()))
            } else {
                completion(.failure(errors.first!))
            }
        }
    }

    // MARK: - Validation

    func validateStockAvailability(
        for items: [OrderItemModel], completion: @escaping ([StockWarning]) -> Void
    ) {
        // This requires fetching recipes for all products in the order
        // For MVP, we'll implement a simplified check or iterate asynchronously
        // Ideally, we need a bulk fetch method.

        var warnings: [StockWarning] = []
        let dispatchGroup = DispatchGroup()

        // Dictionary to aggregate required quantities per ingredient
        var requiredIngredients: [String: Double] = [:]

        // 1. Calculate requirements
        for item in items {
            dispatchGroup.enter()
            databaseService.fetchRecipe(forProductId: item.productId) { recipeItems in
                for recipeItem in recipeItems {
                    let totalRequired = recipeItem.quantity * Double(item.quantity)
                    requiredIngredients[recipeItem.ingredientId, default: 0] += totalRequired
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            // 2. Check stock against requirements
            let checkGroup = DispatchGroup()

            for (ingredientId, requiredQty) in requiredIngredients {
                checkGroup.enter()
                self?.databaseService.fetchIngredient(byId: ingredientId) { ingredient in
                    if let ingredient = ingredient {
                        if ingredient.stockQuantity < requiredQty {
                            warnings.append(
                                StockWarning(
                                    ingredientId: ingredientId,
                                    ingredientName: ingredient.name,
                                    requiredQty: requiredQty,
                                    currentStock: ingredient.stockQuantity
                                ))
                        }
                    }
                    checkGroup.leave()
                }
            }

            checkGroup.notify(queue: .main) {
                completion(warnings)
            }
        }
    }
}
