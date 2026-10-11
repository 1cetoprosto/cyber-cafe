//
//  CostingService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

protocol CostingServiceProtocol {
    func calculateProductCost(productId: String) async -> Double
    func calculateOrderCOGS(items: [OrderItemModel]) async -> Double
    func calculateOrderMetrics(items: [OrderItemModel]) -> (totalSale: Double, totalCost: Double)
}

class CostingService: CostingServiceProtocol {
    static let shared = CostingService()
    private let databaseService: DomainDB

    private init(databaseService: DomainDB = DomainDatabaseService.shared) {
        self.databaseService = databaseService
    }

    // MARK: - Product Cost Calculation

    func calculateProductCost(productId: String) async -> Double {
        let recipeItems = await databaseService.fetchRecipe(forProductId: productId)
        guard !recipeItems.isEmpty else { return 0.0 }

        var totalCost: Double = 0.0

        await withTaskGroup(of: Double.self) { group in
            for item in recipeItems {
                group.addTask {
                    let ingredient = await self.databaseService.fetchIngredient(
                        byId: item.ingredientId)
                    return (ingredient?.averageCost ?? 0.0) * item.quantity
                }
            }

            for await ingredientCost in group {
                totalCost += ingredientCost
            }
        }

        return totalCost
    }

    // MARK: - Order COGS Calculation

    func calculateOrderCOGS(items: [OrderItemModel]) async -> Double {
        var totalOrderCOGS: Double = 0.0

        await withTaskGroup(of: Double.self) { group in
            for item in items {
                group.addTask {
                    let unitCost = await self.calculateProductCost(productId: item.productId)
                    return unitCost * Double(item.quantity)
                }
            }

            for await itemCOGS in group {
                totalOrderCOGS += itemCOGS
            }
        }

        return totalOrderCOGS
    }

    func calculateOrderMetrics(items: [OrderItemModel]) -> (totalSale: Double, totalCost: Double) {
        let totalSale = items.reduce(0) { $0 + $1.totalSale }
        let totalCost = items.reduce(0) { $0 + $1.totalCost }
        return (totalSale, totalCost)
    }
}
