//
//  CreatePurchaseViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

protocol CreatePurchaseViewModelType {
    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void)
    func savePurchase(date: Date, ingredientId: String, quantity: Double, price: Double, completion: @escaping (Bool, String?) -> Void)
}

class CreatePurchaseViewModel: CreatePurchaseViewModelType {
    
    private let inventoryService: InventoryServiceProtocol
    private let databaseService: DomainDB // Use Protocol if available, or class
    
    init(inventoryService: InventoryServiceProtocol = InventoryService.shared,
         databaseService: DomainDB = DomainDatabaseService.shared) {
        self.inventoryService = inventoryService
        self.databaseService = databaseService
    }
    
    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void) {
        databaseService.fetchIngredients { ingredients in
            completion(ingredients)
        }
    }
    
    func savePurchase(date: Date, ingredientId: String, quantity: Double, price: Double, completion: @escaping (Bool, String?) -> Void) {
        // Validation
        guard quantity > 0 else {
            completion(false, "Quantity must be greater than 0")
            return
        }
        guard price >= 0 else {
            completion(false, "Price cannot be negative")
            return
        }
        
        let purchase = PurchaseModel(
            date: date,
            ingredientId: ingredientId,
            quantity: quantity,
            price: price
        )
        
        // Use InventoryService to process purchase (update stock/avgCost)
        inventoryService.processPurchase(purchase: purchase) { result in
            switch result {
            case .success:
                completion(true, nil)
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }
}
