//
//  CostingService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

protocol CostingServiceProtocol {
    func calculateProductCost(productId: String, completion: @escaping (Double) -> Void)
    func calculateOrderCOGS(items: [OrderItemModel], completion: @escaping (Double) -> Void)
}

class CostingService: CostingServiceProtocol {
    static let shared = CostingService()
    private let databaseService = DomainDatabaseService.shared
    
    private init() {}
    
    // MARK: - Product Cost Calculation
    
    func calculateProductCost(productId: String, completion: @escaping (Double) -> Void) {
        // Cost = Sum(Ingredient.avgCost * RecipeItem.qty)
        
        databaseService.fetchRecipe(forProductId: productId) { [weak self] recipeItems in
            guard !recipeItems.isEmpty else {
                completion(0.0)
                return
            }
            
            var totalCost: Double = 0.0
            let group = DispatchGroup()
            
            for item in recipeItems {
                group.enter()
                self?.databaseService.fetchIngredient(byId: item.ingredientId) { ingredient in
                    if let ingredient = ingredient {
                        totalCost += ingredient.averageCost * item.quantity
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(totalCost)
            }
        }
    }
    
    // MARK: - Order COGS Calculation
    
    func calculateOrderCOGS(items: [OrderItemModel], completion: @escaping (Double) -> Void) {
        var totalOrderCOGS: Double = 0.0
        let group = DispatchGroup()
        
        for item in items {
            group.enter()
            calculateProductCost(productId: item.productId) { unitCost in
                totalOrderCOGS += unitCost * Double(item.quantity)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(totalOrderCOGS)
        }
    }
}
