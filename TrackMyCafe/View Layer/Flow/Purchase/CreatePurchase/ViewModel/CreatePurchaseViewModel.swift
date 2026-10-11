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

    func fetchIngredients() async -> [IngredientModel]
    func savePurchase(
        date: Date, ingredientId: String, quantity: Double, price: Double,
        totalAmount: Double,
        paymentAccount: PaymentAccount
    ) async -> (Bool, String?)
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

    func fetchIngredients() async -> [IngredientModel] {
        await databaseService.fetchIngredients()
    }

    func savePurchase(
        date: Date, ingredientId: String, quantity: Double, price: Double,
        totalAmount: Double,
        paymentAccount: PaymentAccount
    ) async -> (Bool, String?) {
        // Validation
        guard quantity > 0 else {
            return (false, "Quantity must be greater than 0")
        }
        guard price >= 0 else {
            return (false, "Price cannot be negative")
        }
        guard totalAmount >= 0 else {
            return (false, "Total amount cannot be negative")
        }

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
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
