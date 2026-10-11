//
//  DomainDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.05.2024.
//

import Foundation

protocol DomainDB {
    // MARK: - Order Products (OrderItemModel)
    func updateProduct(
        model: OrderItemModel, date: Date, name: String, quantity: Int, price: Double,
        sum: Double) async
    func fetchProduct(forDate date: Date) async -> [OrderItemModel]
    func fetchProduct(forDate date: Date, withName name: String) async -> OrderItemModel?
    func fetchProduct(withOrderId id: String) async -> [OrderItemModel]
    func fetchProductsOfOrders(from startDate: Date, to endDate: Date) async
        -> [OrderItemModel]
    func fetchOrderItems(withOrderId id: String) async -> [OrderItemModel]
    func saveProduct(order: OrderItemModel) async -> String?
    func deleteProduct(order: OrderItemModel) async -> Bool

    // MARK: - Orders
    func updateOrders(
        model: OrderModel,
        date: Date,
        type: String,
        total: Double,
        cashAmount: Double,
        cardAmount: Double,
        totalCost: Double,
        note: String?) async
    func fetchOrders() async -> [OrderModel]
    func fetchSectionsOfOrders() async -> [(date: Date, items: [OrderModel])]
    func fetchOrders(forId id: String) async -> OrderModel?
    func saveOrder(order: OrderModel) async -> String?
    func deleteOrder(order: OrderModel) async -> Bool
    func hasAnyOrderWithInventoryTracking() async -> Bool

    // MARK: - Products Price
    func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double) async
    func fetchProductsPrice() async -> [ProductsPriceModel]
    func saveProductsPrice(productPrice: ProductsPriceModel) async -> Bool
    func deleteProductsPrice(model: ProductsPriceModel) async -> Bool

    // MARK: - Opex Expenses
    func updateOpexExpense(model: OpexExpenseModel) async
    func fetchOpexExpenses() async -> [OpexExpenseModel]
    func fetchSectionsOfOpexExpenses() async -> [(date: Date, items: [OpexExpenseModel])]
    func saveOpexExpense(model: OpexExpenseModel) async -> String?
    func deleteOpexExpense(model: OpexExpenseModel) async -> Bool

    // MARK: - Journal entries
    func saveJournalEntry(model: JournalEntryModel) async -> String?
    func fetchJournalEntries() async -> [JournalEntryModel]

    // MARK: - Daily balances
    func saveDailyBalance(model: DailyBalanceModel) async -> Bool
    func fetchDailyBalance(forAccount account: PaymentAccount, date: Date) async
        -> DailyBalanceModel?
    func fetchDailyBalances(
        forAccount account: PaymentAccount,
        from startDate: Date,
        to endDate: Date
    ) async -> [DailyBalanceModel]

    // MARK: - Types
    func updateType(model: TypeModel, type: String) async
    func fetchTypes() async -> [TypeModel]
    func saveType(model: TypeModel) async -> Bool
    func deleteType(model: TypeModel) async -> Bool
    func setDefaultType(model: TypeModel, isDefault: Bool) async

    // MARK: - Ingredients
    func fetchIngredients() async -> [IngredientModel]
    func fetchIngredient(byId id: String) async -> IngredientModel?
    func saveIngredient(model: IngredientModel) async -> Bool
    func deleteIngredient(model: IngredientModel) async -> Bool

    // MARK: - Purchases
    func fetchPurchases() async -> [PurchaseModel]
    func savePurchase(model: PurchaseModel) async -> Bool
    func deletePurchase(model: PurchaseModel) async -> Bool

    // MARK: - Recipes
    func fetchRecipe(forProductId productId: String) async -> [RecipeItemModel]

    // MARK: - Inventory Adjustments
    func saveInventoryAdjustment(model: InventoryAdjustmentModel) async -> String?
    func fetchInventoryAdjustments() async -> [InventoryAdjustmentModel]
    func fetchInventoryAdjustments(
        from startDate: Date?,
        to endDate: Date?,
        ingredientId: String?,
        bulkSessionId: String?
    ) async -> [InventoryAdjustmentModel]

    // MARK: - Product Categories
    func fetchProductCategories() async -> [ProductCategoryModel]
    func saveProductCategory(model: ProductCategoryModel) async -> Bool
    func deleteProductCategory(model: ProductCategoryModel) async -> Bool

    // MARK: - Database
    func deleteActiveDatabaseData() async -> Bool

    // MARK: - Test Data
    func seedTestData(forDays days: Int) async
}
