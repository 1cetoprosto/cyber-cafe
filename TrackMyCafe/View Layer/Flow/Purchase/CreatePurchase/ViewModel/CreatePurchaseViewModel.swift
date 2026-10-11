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
    var initialTotalAmount: Double { get }
    var initialPaymentAccount: PaymentAccount? { get }

    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void)
    func savePurchase(
        date: Date, ingredientId: String, quantity: Double, price: Double,
        totalAmount: Double,
        paymentAccount: PaymentAccount,
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
        guard let quantity = purchaseToEdit?.quantity else { return "" }
        // Remove trailing zeros if integer
        return quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity) : String(quantity)
    }
    var initialPrice: String {
        guard let price = purchaseToEdit?.price else { return "" }
        return price.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", price) : String(price)
    }
    var initialTotalAmount: Double { purchaseToEdit?.totalAmount ?? 0 }
    var initialPaymentAccount: PaymentAccount? { purchaseToEdit?.paymentAccount }

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
        Task {
            let ingredients = await databaseService.fetchIngredients()
            completion(ingredients)
        }
    }

    func savePurchase(
        date: Date, ingredientId: String, quantity: Double, price: Double,
        totalAmount: Double,
        paymentAccount: PaymentAccount,
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
        guard totalAmount >= 0 else {
            completion(false, "Total amount cannot be negative")
            return
        }

        Task { [weak self] in
            guard let self = self else { return }

            do {
                if let oldPurchase = purchaseToEdit {
                    let newPurchase = PurchaseModel(
                        id: oldPurchase.id,
                        date: date,
                        ingredientId: ingredientId,
                        quantity: quantity,
                        price: price,
                        totalAmount: totalAmount,
                        paymentAccount: paymentAccount
                    )

                    try await inventoryService.editPurchase(
                        oldPurchase: oldPurchase, newPurchase: newPurchase)
                } else {
                    let purchase = PurchaseModel(
                        date: date,
                        ingredientId: ingredientId,
                        quantity: quantity,
                        price: price,
                        totalAmount: totalAmount,
                        paymentAccount: paymentAccount
                    )

                    try await inventoryService.processPurchase(purchase: purchase)
                }
                completion(true, nil)
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
}
