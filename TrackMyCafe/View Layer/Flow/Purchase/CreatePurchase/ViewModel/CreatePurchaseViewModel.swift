//
//  CreatePurchaseViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

protocol CreatePurchaseViewModelType {
    var isEditing: Bool { get }
    var initialDate: Date { get }
    var initialIngredientId: String? { get }
    var initialQuantity: String { get }
    var initialPrice: String { get }
    
    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void)
    func savePurchase(
        date: Date, ingredientId: String, quantity: Double, price: Double,
        completion: @escaping (Bool, String?) -> Void)
}

class CreatePurchaseViewModel: CreatePurchaseViewModelType {

    private let inventoryService: InventoryServiceProtocol
    private let databaseService: DomainDB
    private let purchaseToEdit: PurchaseModel?

    var isEditing: Bool { purchaseToEdit != nil }
    
    var initialDate: Date { purchaseToEdit?.date ?? Date() }
    var initialIngredientId: String? { purchaseToEdit?.ingredientId }
    var initialQuantity: String {
        guard let q = purchaseToEdit?.quantity else { return "" }
        // Remove trailing zeros if integer
        return q.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", q) : String(q)
    }
    var initialPrice: String {
        guard let p = purchaseToEdit?.price else { return "" }
        return p.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", p) : String(p)
    }

    init(
        purchaseToEdit: PurchaseModel? = nil,
        inventoryService: InventoryServiceProtocol = InventoryService.shared,
        databaseService: DomainDB = DomainDatabaseService.shared
    ) {
        self.purchaseToEdit = purchaseToEdit
        self.inventoryService = inventoryService
        self.databaseService = databaseService
    }

    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void) {
        databaseService.fetchIngredients { ingredients in
            completion(ingredients)
        }
    }

    func savePurchase(
        date: Date, ingredientId: String, quantity: Double, price: Double,
        completion: @escaping (Bool, String?) -> Void
    ) {
        // Validation
        guard quantity > 0 else {
            completion(false, "Quantity must be greater than 0")
            return
        }
        guard price >= 0 else {
            completion(false, "Price cannot be negative")
            return
        }

        if let oldPurchase = purchaseToEdit {
            let newPurchase = PurchaseModel(
                id: oldPurchase.id,
                date: date,
                ingredientId: ingredientId,
                quantity: quantity,
                price: price
            )
            
            inventoryService.editPurchase(oldPurchase: oldPurchase, newPurchase: newPurchase) { result in
                switch result {
                case .success:
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error.localizedDescription)
                }
            }
        } else {
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
}
