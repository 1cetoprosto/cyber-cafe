//
//  DomainDB.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.05.2024.
//

import Foundation

protocol DomainDB {
    // Asynchronous method for updating sales data
    func updateProduct(
        model: ProductOfOrderModel, date: Date, name: String, quantity: Int, price: Double,
        sum: Double)

    // Asynchronous method for getting a sales list for a specific date
    func fetchProduct(forDate date: Date, completion: @escaping ([ProductOfOrderModel]) -> Void)

    // Asynchronous method for getting sales for a specific date and title
    func fetchProduct(
        forDate date: Date, withName name: String,
        completion: @escaping (ProductOfOrderModel?) -> Void)

    // Order Products (ProductOfOrder)
    func fetchProduct(withOrderId id: String, completion: @escaping ([ProductOfOrderModel]) -> Void)
    func saveProduct(order: ProductOfOrderModel, completion: @escaping (Bool) -> Void)
    func deleteProduct(order: ProductOfOrderModel, completion: @escaping (Bool) -> Void)

    // Asynchronous methods for updating and retrieving sales data
    func updateOrders(
        model: OrderModel, date: Date, type: String, total: Double, cashAmount: Double,
        cardAmount: Double)
    func fetchOrders(completion: @escaping ([OrderModel]) -> Void)
    func fetchSectionsOfOrders(completion: @escaping ([(date: Date, items: [OrderModel])]) -> Void)
    func fetchOrders(forId id: String, completion: @escaping (OrderModel?) -> Void)
    func saveOrder(order: OrderModel, completion: @escaping (String?) -> Void)
    func deleteOrder(order: OrderModel, completion: @escaping (Bool) -> Void)

    // Asynchronous methods for updating and retrieving product data
    func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double)
    func fetchProductsPrice(completion: @escaping ([ProductsPriceModel]) -> Void)
    func saveProductsPrice(productPrice: ProductsPriceModel, completion: @escaping (Bool) -> Void)
    func deleteProductsPrice(model: ProductsPriceModel, completion: @escaping (Bool) -> Void)

    // Asynchronous methods for updating and retrieving purchase data
    func updateOpexExpense(model: OpexExpenseModel)
    func fetchOpexExpenses(completion: @escaping ([OpexExpenseModel]) -> Void)
    func fetchSectionsOfOpexExpenses(completion: @escaping ([(date: Date, items: [OpexExpenseModel])]) -> Void)
    func saveOpexExpense(model: OpexExpenseModel, completion: @escaping (Bool) -> Void)
    func deleteOpexExpense(model: OpexExpenseModel, completion: @escaping (Bool) -> Void)

    // Asynchronous methods for updating and retrieving data on income types
    func updateType(model: TypeModel, type: String)
    func fetchTypes(completion: @escaping ([TypeModel]) -> Void)
    func saveType(model: TypeModel, completion: @escaping (Bool) -> Void)
    func deleteType(model: TypeModel, completion: @escaping (Bool) -> Void)
    func setDefaultType(model: TypeModel, isDefault: Bool)

    // Ingredients
    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void)
    func fetchIngredient(byId id: String, completion: @escaping (IngredientModel?) -> Void)
    func saveIngredient(model: IngredientModel, completion: @escaping (Bool) -> Void)
    func deleteIngredient(model: IngredientModel, completion: @escaping (Bool) -> Void)

    // Purchases
    func fetchPurchases(completion: @escaping ([PurchaseModel]) -> Void)
    func savePurchase(model: PurchaseModel, completion: @escaping (Bool) -> Void)

    // Recipes
    func fetchRecipe(
        forProductId productId: String, completion: @escaping ([RecipeItemModel]) -> Void)

    // Asynchronous method for deleting data from the active database
    func deleteActiveDatabaseData(completion: @escaping (Bool) -> Void)

    // Test Data & Migration
    func seedTestData(forDays days: Int) async
    // Removed Realm migration methods
    // func transferDataFromRealmToFIR(completion: @escaping () -> Void)
    // func transferDataFromFIRToRealm(completion: @escaping () -> Void)
}
