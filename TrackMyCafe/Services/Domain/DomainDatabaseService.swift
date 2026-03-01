//
//  Repository.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation
import RealmSwift
import os.log

class DomainDatabaseService: DomainDB {

    static let shared = DomainDatabaseService()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!, category: "DomainDatabaseService")

    // Метод для перевірки, чи включений режим онлайн
    // private func isOnlineModeEnabled() -> Bool {
    //     return SettingsManager.shared.loadOnline()
    // }

    // MARK: - Ingredient Operations

    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.ingredients, firModel: FIRIngredientModel.self
        ) { result in
            switch result {
            case .success(let firModels):
                let models = firModels.map { IngredientModel(firebaseModel: $0.1) }
                completion(models)
            case .failure(let error):
                self.logger.error(
                    "Error fetching ingredients from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func saveIngredient(model: IngredientModel, completion: @escaping (Bool) -> Void) {
        let firModel = FIRIngredientModel(dataModel: model)
        FirestoreDatabaseService.shared.update(
            firModel: firModel, collection: FirebaseCollections.ingredients,
            documentId: model.id
        ) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to save ingredient to Firestore: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func deleteIngredient(model: IngredientModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(
            collection: FirebaseCollections.ingredients, documentId: model.id
        ) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                self.logger.error("Failed to delete ingredient from Firestore: \(error)")
                completion(false)
            }
        }
    }

    // MARK: - New Methods (Step 4 & Purchase)

    func fetchIngredient(byId id: String, completion: @escaping (IngredientModel?) -> Void) {
        FirestoreDatabaseService.shared.fetchObjectById(
            ofType: FIRIngredientModel.self, collection: FirebaseCollections.ingredients, id: id
        ) { result in
            switch result {
            case .success(let firModel):
                completion(IngredientModel(firebaseModel: firModel))
            case .failure(let error):
                self.logger.error(
                    "Error fetching ingredient from Firestore: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    // Purchases
    func fetchPurchases(completion: @escaping ([PurchaseModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.purchases, firModel: FIRPurchaseModel.self
        ) { result in
            switch result {
            case .success(let firPurchases):
                let models = firPurchases.map { PurchaseModel(firebaseModel: $0.1) }
                completion(models)
            case .failure(let error):
                self.logger.error(
                    "Error fetching purchases from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func savePurchase(model: PurchaseModel, completion: @escaping (Bool) -> Void) {
        let firModel = FIRPurchaseModel(dataModel: model)
        FirestoreDatabaseService.shared.update(
            firModel: firModel, collection: FirebaseCollections.purchases,
            documentId: model.id
        ) { result in
            switch result {
            case .success:
                self.logger.info("Purchase saved to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to save purchase to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    // Recipes
    func fetchRecipe(
        forProductId productId: String, completion: @escaping ([RecipeItemModel]) -> Void
    ) {
        FirestoreDatabaseService.shared.fetchObjectById(
            ofType: FIRProductsPriceModel.self,
            collection: FirebaseCollections.productsPrice,
            id: productId
        ) { result in
            switch result {
            case .success(let product):
                let recipeItems = product.recipe.map { RecipeItemModel(firebaseModel: $0) }
                completion(recipeItems)
            case .failure(let error):
                self.logger.error(
                    "Error fetching recipe from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    // MARK: - Product Operations

    func updateProduct(
        model: ProductOfOrderModel, date: Date, name: String, quantity: Int, price: Double,
        sum: Double
    ) {
        var updatedModel = FIRProductModel(dataModel: model)
        updatedModel.date = date
        updatedModel.name = name
        updatedModel.quantity = quantity
        updatedModel.price = price
        updatedModel.amount = sum

        FirestoreDatabaseService.shared.update(
            firModel: updatedModel, collection: FirebaseCollections.productOfOrders,
            documentId: model.id
        ) { result in
            switch result {
            case .success():
                self.logger.info("Order product updated successfully in Firestore database")
            case .failure(let error):
                self.logger.error(
                    "Failed to update order product in Firestore database: \(error.localizedDescription)"
                )
            }
        }
    }

    func fetchProduct(forDate date: Date, completion: @escaping ([ProductOfOrderModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self
        ) { result in
            switch result {
            case .success(let firProducts):
                let ordersProduct = firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
                completion(ordersProduct)
            case .failure(let error):
                self.logger.error(
                    "Error fetching products from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func fetchProduct(
        forDate date: Date, withName name: String,
        completion: @escaping (ProductOfOrderModel?) -> Void
    ) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self
        ) { result in
            switch result {
            case .success(let firProducts):
                let ordersProduct = firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
                let filteredProduct = ordersProduct.first { $0.date == date && $0.name == name }
                completion(filteredProduct)
            case .failure(let error):
                self.logger.error(
                    "Error fetching products from Firestore: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    func fetchProduct(withOrderId id: String, completion: @escaping ([ProductOfOrderModel]) -> Void)
    {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self
        ) { result in
            switch result {
            case .success(let firProducts):
                let ordersProduct = firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
                let filteredProduct = ordersProduct.filter { $0.orderId == id }
                completion(filteredProduct)
            case .failure(let error):
                self.logger.error(
                    "Error fetching products from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func saveProduct(order: ProductOfOrderModel, completion: @escaping (String?) -> Void) {
        FirestoreDatabaseService.shared.create(
            firModel: FIRProductModel(dataModel: order),
            collection: FirebaseCollections.productOfOrders
        ) { result in
            switch result {
            case .success(let id):
                self.logger.info("Order product saved to Firestore successfully with ID: \(id)")
                completion(id)
            case .failure(let error):
                self.logger.error(
                    "Failed to save order product to Firestore with error: \(error.localizedDescription)"
                )
                completion(nil)
            }
        }
    }

    func deleteProduct(order: ProductOfOrderModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(
            collection: FirebaseCollections.productOfOrders, documentId: order.id
        ) {
            result in
            switch result {
            case .success:
                self.logger.info("Order product deleted to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to delete order product to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    // MARK: - Orders Operations

    func updateOrders(
        model: OrderModel,
        date: Date,
        type: String,
        total: Double,
        cashAmount: Double,
        cardAmount: Double,
        totalCost: Double
    ) {
        var updatedModel = FIROrderModel(dataModel: model)
        updatedModel.date = date
        updatedModel.type = type
        updatedModel.sum = total
        updatedModel.cash = cashAmount
        updatedModel.card = cardAmount
        updatedModel.totalCost = totalCost
        FirestoreDatabaseService.shared.update(
            firModel: updatedModel, collection: FirebaseCollections.orders, documentId: model.id
        ) { result in
            switch result {
            case .success():
                self.logger.info("Order updated successfully in Firestore database")
            case .failure(let error):
                self.logger.error(
                    "Failed to update order in Firestore database: \(error.localizedDescription)"
                )
            }
        }
    }

    func fetchOrders(completion: @escaping ([OrderModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.orders, firModel: FIROrderModel.self
        ) {
            result in
            switch result {
            case .success(let firOrders):
                let orders = firOrders.map { OrderModel(firebaseModel: $1) }
                completion(orders)
            case .failure(let error):
                self.logger.error(
                    "Error fetching products from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func fetchSectionsOfOrders(completion: @escaping ([(date: Date, items: [OrderModel])]) -> Void)
    {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.orders, firModel: FIROrderModel.self
        ) {
            result in
            switch result {
            case .success(let firOrders):
                let calendar = Calendar.current
                let groupedOrders = Dictionary(
                    grouping: firOrders.map { OrderModel(firebaseModel: $1) },
                    by: { order -> Date in
                        let dateComponents = calendar.dateComponents(
                            [.year, .month, .day], from: order.date)
                        return calendar.date(from: dateComponents)!
                    })
                let sections = groupedOrders.map { (date: $0.key, items: $0.value) }
                    .sorted { $0.date > $1.date }
                completion(sections)
            case .failure(let error):
                self.logger.error(
                    "Error fetching orders from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func fetchOrders(forId id: String, completion: @escaping (OrderModel?) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.orders, firModel: FIROrderModel.self
        ) {
            result in
            switch result {
            case .success(let firOrders):
                let orders = firOrders.map { OrderModel(firebaseModel: $1) }
                completion(
                    orders.filter { $0.id == id }
                        .first)
            case .failure(let error):
                self.logger.error(
                    "Error fetching orders from Firestore: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    func saveOrder(order: OrderModel, completion: @escaping (String?) -> Void) {
        FirestoreDatabaseService.shared.create(
            firModel: FIROrderModel(dataModel: order), collection: FirebaseCollections.orders
        ) { result in
            switch result {
            case .success(let documentId):
                self.logger.info("Order saved to Firestore successfully")
                completion(documentId)
            case .failure(let error):
                self.logger.error(
                    "Failed to save order to Firestore with error: \(error.localizedDescription)"
                )
                completion(nil)
            }
        }
    }

    func deleteOrder(order: OrderModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(
            collection: FirebaseCollections.orders, documentId: order.id
        ) { result in
            switch result {
            case .success:
                self.logger.info("Order deleted to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to delete order to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    // MARK: - ProductsPrice Operations

    func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double) {
        var updatedModel = FIRProductsPriceModel(dataModel: model)
        updatedModel.name = name
        updatedModel.price = price
        FirestoreDatabaseService.shared.update(
            firModel: updatedModel, collection: FirebaseCollections.productsPrice,
            documentId: model.id
        ) { result in
            switch result {
            case .success():
                self.logger.info("Product price updated successfully in Firestore database")
            case .failure(let error):
                self.logger.error(
                    "Failed to update product price in Firestore database: \(error.localizedDescription)"
                )
            }
        }
    }

    func fetchProductsPrice(completion: @escaping ([ProductsPriceModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.productsPrice,
            firModel: FIRProductsPriceModel.self
        ) { result in
            switch result {
            case .success(let firProducts):
                let products = firProducts.map { ProductsPriceModel(firebaseModel: $1) }
                completion(products)
            case .failure(let error):
                self.logger.error(
                    "Error fetching products from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func saveProductsPrice(productPrice: ProductsPriceModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.update(
            firModel: FIRProductsPriceModel(dataModel: productPrice),
            collection: FirebaseCollections.productsPrice,
            documentId: productPrice.id
        ) { result in
            switch result {
            case .success:
                self.logger.info("Product price saved to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to save product price to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    func deleteProductsPrice(model: ProductsPriceModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(
            collection: FirebaseCollections.productsPrice, documentId: model.id
        ) {
            result in
            switch result {
            case .success:
                self.logger.info("productsPrice deleted to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to productsPrice order to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    // MARK: - Product Categories Operations

    func fetchProductCategories(completion: @escaping ([ProductCategoryModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.productCategories,
            firModel: FIRProductCategoryModel.self
        ) { result in
            switch result {
            case .success(let firCategories):
                let categories = firCategories.map { ProductCategoryModel(firebaseModel: $1) }
                completion(categories.sorted { $0.sortOrder < $1.sortOrder })
            case .failure(let error):
                self.logger.error(
                    "Error fetching product categories from Firestore: \(error.localizedDescription)"
                )
                completion([])
            }
        }
    }

    func saveProductCategory(category: ProductCategoryModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.update(
            firModel: FIRProductCategoryModel(dataModel: category),
            collection: FirebaseCollections.productCategories,
            documentId: category.id
        ) { result in
            switch result {
            case .success:
                self.logger.info("Product category saved to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to save product category to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    func deleteProductCategory(model: ProductCategoryModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(
            collection: FirebaseCollections.productCategories,
            documentId: model.id
        ) { result in
            switch result {
            case .success:
                self.logger.info("Product category deleted in Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to delete product category in Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    // MARK: - Cost Operations (Deprecated, use Opex Operations)

    // MARK: - Type Operations

    func updateType(model: TypeModel, type: String) {
        var updatedModel = FIRTypeModel(dataModel: model)
        updatedModel.name = type
        FirestoreDatabaseService.shared.update(
            firModel: updatedModel, collection: FirebaseCollections.types,
            documentId: model.id
        ) { result in
            switch result {
            case .success():
                self.logger.info("Type updated successfully in Firestore database")
            case .failure(let error):
                self.logger.error(
                    "Failed to update type in Firestore database: \(error.localizedDescription)"
                )
            }
        }
    }

    func fetchTypes(completion: @escaping ([TypeModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.types, firModel: FIRTypeModel.self
        ) {
            result in
            switch result {
            case .success(let firTypes):
                let types = firTypes.map { TypeModel(firebaseModel: $1) }
                completion(types)
            case .failure(let error):
                self.logger.error(
                    "Error fetching types from Firestore: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func saveType(model: TypeModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.create(
            firModel: FIRTypeModel(dataModel: model), collection: FirebaseCollections.types
        ) { result in
            switch result {
            case .success(_):
                self.logger.info("Types saved to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to save Types to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    func setDefaultType(model: TypeModel, isDefault: Bool) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.types, firModel: FIRTypeModel.self
        ) { result in
            switch result {
            case .success(let firTypes):
                let types = firTypes.map { TypeModel(firebaseModel: $1) }
                for t in types {
                    var updated = FIRTypeModel(dataModel: t)
                    updated.isDefault = (t.id == model.id) ? isDefault : false
                    FirestoreDatabaseService.shared.update(
                        firModel: updated, collection: FirebaseCollections.types,
                        documentId: t.id
                    ) { _ in }
                }
                self.logger.info("Default type updated in Firestore")
            case .failure(let error):
                self.logger.error(
                    "Failed to update default type in Firestore: \(error.localizedDescription)")
            }
        }
    }

    func deleteType(model: TypeModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(
            collection: FirebaseCollections.types, documentId: model.id
        ) { result in
            switch result {
            case .success:
                self.logger.info("Types deleted to Firestore successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to delete types order to Firestore with error: \(error.localizedDescription)"
                )
                completion(false)
            }
        }
    }

    // MARK: - Inventory Adjustment Operations

    func saveInventoryAdjustment(
        model: InventoryAdjustmentModel, completion: @escaping (String?) -> Void
    ) {
        let firModel = FIRInventoryAdjustmentModel(dataModel: model)
        FirestoreDatabaseService.shared.create(
            firModel: firModel, collection: FirebaseCollections.inventoryAdjustments
        ) { result in
            switch result {
            case .success(let id):
                self.logger.info("Inventory adjustment saved to Firestore successfully")
                completion(id)
            case .failure(let error):
                self.logger.error(
                    "Failed to save inventory adjustment: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    func fetchInventoryAdjustments(completion: @escaping ([InventoryAdjustmentModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.inventoryAdjustments,
            firModel: FIRInventoryAdjustmentModel.self
        ) { result in
            switch result {
            case .success(let firModels):
                let models = firModels.map {
                    InventoryAdjustmentModel(
                        id: $0.1.id ?? "", date: $0.1.date, ingredientId: $0.1.ingredientId,
                        quantityDelta: $0.1.quantityDelta, reason: $0.1.reason)
                }
                completion(models)
            case .failure(let error):
                self.logger.error(
                    "Error fetching inventory adjustments: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    // MARK: - Opex Operations

    func saveOpexExpense(model: OpexExpenseModel, completion: @escaping (String?) -> Void) {
        let firModel = FIROpexExpenseModel(dataModel: model)
        FirestoreDatabaseService.shared.create(
            firModel: firModel, collection: FirebaseCollections.opexExpenses
        ) { result in
            switch result {
            case .success(let id):
                self.logger.info("Opex expense saved to Firestore successfully with ID: \(id)")
                completion(id)
            case .failure(let error):
                self.logger.error("Failed to save opex expense: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    func fetchOpexExpenses(completion: @escaping ([OpexExpenseModel]) -> Void) {
        FirestoreDatabaseService.shared.read(
            collection: FirebaseCollections.opexExpenses, firModel: FIROpexExpenseModel.self
        ) { result in
            switch result {
            case .success(let firModels):
                let models = firModels.map {
                    OpexExpenseModel(
                        id: $0.1.id ?? "", date: $0.1.date, categoryId: $0.1.categoryId,
                        amount: $0.1.amount, note: $0.1.note)
                }
                completion(models)
            case .failure(let error):
                self.logger.error("Error fetching opex expenses: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    func updateOpexExpense(model: OpexExpenseModel) {
        let firModel = FIROpexExpenseModel(dataModel: model)
        FirestoreDatabaseService.shared.update(
            firModel: firModel, collection: FirebaseCollections.opexExpenses,
            documentId: model.id
        ) { result in
            switch result {
            case .success():
                self.logger.info("Opex expense updated successfully")
            case .failure(let error):
                self.logger.error("Failed to update opex expense: \(error.localizedDescription)")
            }
        }
    }

    func deleteOpexExpense(model: OpexExpenseModel, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(
            collection: FirebaseCollections.opexExpenses, documentId: model.id
        ) { result in
            switch result {
            case .success:
                self.logger.info("Opex expense deleted successfully")
                completion(true)
            case .failure(let error):
                self.logger.error("Failed to delete opex expense: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func fetchSectionsOfOpexExpenses(
        completion: @escaping ([(date: Date, items: [OpexExpenseModel])]) -> Void
    ) {
        fetchOpexExpenses { expenses in
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: expenses) { expense in
                let components = calendar.dateComponents([.year, .month, .day], from: expense.date)
                return calendar.date(from: components)!
            }
            let sections = grouped.map { (date: $0.key, items: $0.value) }
                .sorted { $0.date > $1.date }
            completion(sections)
        }
    }

    // MARK: - delete Operations

    func deleteActiveDatabaseData(completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.deleteAllData { success in
            if success {
                self.logger.log("All data deleted successfully from Firestore database")
                // Also clear demo data manifest if it exists
                DemoDataManager.shared.clearManifest()
                completion(true)
            } else {
                self.logger.log("Failed to delete data from Firestore database")
                completion(false)
            }
        }
    }

    // MARK: - Generic Delete Operation
    func delete(collection: String, documentId: String, completion: @escaping (Bool) -> Void) {
        FirestoreDatabaseService.shared.delete(collection: collection, documentId: documentId) {
            result in
            switch result {
            case .success:
                self.logger.info("Document \(documentId) deleted from \(collection) successfully")
                completion(true)
            case .failure(let error):
                self.logger.error(
                    "Failed to delete document \(documentId) from \(collection): \(error)")
                completion(false)
            }
        }
    }

    // MARK: - general Operations

    var orderIdMap: [String: String] = [:]

    // Removed Realm migration methods as we are fully Firestore based now
    // func transferDataFromFIRToRealm(completion: @escaping () -> Void) { ... }
    // func transferDataFromRealmToFIR(completion: @escaping () -> Void) { ... }

    @MainActor
    func seedTestData(forDays days: Int) async {
        await cleanDatabase()
        var manifest: DemoDataManifest? = nil
        await seedDemoData(days: days, manifest: &manifest)
    }

    @MainActor
    func seedUserDemoData() async {
        // Clear old manifest if exists before starting new seeding
        DemoDataManager.shared.clearManifest()

        var manifest: DemoDataManifest? = nil  // We don't use this local manifest anymore for persistence, but keep signature
        await seedDemoData(days: 14, manifest: &manifest)
    }

    @MainActor
    private func seedDemoData(days: Int, manifest: inout DemoDataManifest?) async {
        // Wait a bit to ensure Firestore processes deletions
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        let isUkrainian = Locale.current.languageCode == "uk"

        let types = await seedTypes(manifest: &manifest)
        var products = await seedProducts(isUkrainian: isUkrainian, manifest: &manifest)
        var ingredients = await seedIngredients(isUkrainian: isUkrainian, manifest: &manifest)

        await assignRecipes(to: &products, ingredients: ingredients, isUkrainian: isUkrainian)

        await generateDailyActivity(
            days: days,
            products: products,
            ingredients: &ingredients,
            types: types,
            isUkrainian: isUkrainian,
            manifest: &manifest
        )

        // Save manifest to UserDefaults once after all generation is complete
        DemoDataManager.shared.saveCurrentManifest()
    }
}

// MARK: - Seeding Helpers
extension DomainDatabaseService {

    fileprivate func cleanDatabase() async {
        await withCheckedContinuation { continuation in
            self.deleteActiveDatabaseData { _ in
                continuation.resume()
            }
        }
    }

    fileprivate func seedTypes(manifest: inout DemoDataManifest?) async -> [TypeModel] {
        let typeHall = R.string.global.typeHall()
        let typeTakeaway = R.string.global.typeTakeaway()
        let typeDelivery = R.string.global.typeDelivery()
        let types: [TypeModel] = [
            TypeModel(id: UUID().uuidString, name: typeHall, isDefault: true),
            TypeModel(id: UUID().uuidString, name: typeTakeaway, isDefault: false),
            TypeModel(id: UUID().uuidString, name: typeDelivery, isDefault: false),
        ]

        for t in types {
            DemoDataManager.shared.addTypeId(t.id)
            await withCheckedContinuation { continuation in
                self.saveType(model: t) { success in
                    if !success { self.logger.error("Failed to seed type: \(t.name)") }
                    continuation.resume()
                }
            }
        }
        return types
    }

    fileprivate func seedProducts(isUkrainian: Bool, manifest: inout DemoDataManifest?) async
        -> [ProductsPriceModel]
    {
        let catalog: [(uk: String, en: String, price: Double)] = [
            ("Еспресо", "Espresso", 8),
            ("Еспресо з молоком", "Espresso with milk", 10),
            ("Американо", "Americano", 8),
            ("Американо з молоком", "Americano with milk", 12),
            ("Капучіно", "Cappuccino", 15),
            ("Лате", "Latte", 20),
            ("Лате макіато", "Latte macchiato", 20),
            ("Айріш", "Irish", 14),
            ("Айріш великий", "Irish large", 16),
            ("Гарячий шоколад", "Hot chocolate", 12),
            ("Гарячий шоколад великий", "Hot chocolate large", 16),
            ("Какао", "Cocoa", 10),
            ("Дитяче лате", "Kids latte", 15),
            ("Чай", "Tea", 5),
            ("Айс лате", "Ice latte", 15),
        ]

        let products: [ProductsPriceModel] = catalog.map { entry in
            let name = isUkrainian ? entry.uk : entry.en
            return ProductsPriceModel(id: UUID().uuidString, name: name, price: entry.price)
        }

        for p in products {
            DemoDataManager.shared.addProductId(p.id)
            await withCheckedContinuation { continuation in
                self.saveProductsPrice(productPrice: p) { success in
                    if !success { self.logger.error("Failed to seed product: \(p.name)") }
                    continuation.resume()
                }
            }
        }
        return products
    }

    fileprivate func seedIngredients(isUkrainian: Bool, manifest: inout DemoDataManifest?) async
        -> [IngredientModel]
    {
        let ingredientCatalog: [(uk: String, en: String, unit: MeasurementUnit, baseCost: Double)] =
            [
                ("Молоко", "Milk", .l, 35.0),
                ("Кавові зерна", "Coffee Beans", .kg, 600.0),
                ("Цукор", "Sugar", .kg, 30.0),
                ("Стаканчики", "Cups", .pcs, 3.5),
                ("Сироп Карамель", "Caramel Syrup", .ml, 0.5),
                ("Вода", "Water", .l, 2.0),
            ]

        var createdIngredients: [IngredientModel] = []

        for item in ingredientCatalog {
            let name = isUkrainian ? item.uk : item.en
            let ingredient = IngredientModel(
                id: UUID().uuidString,
                name: name,
                averageCost: item.baseCost,
                stockQuantity: 0,
                unit: item.unit
            )
            createdIngredients.append(ingredient)
            DemoDataManager.shared.addIngredientId(ingredient.id)

            await withCheckedContinuation { continuation in
                self.saveIngredient(model: ingredient) { success in
                    if !success { self.logger.error("Failed to seed ingredient: \(name)") }
                    continuation.resume()
                }
            }
        }
        return createdIngredients
    }

    fileprivate func assignRecipes(
        to products: inout [ProductsPriceModel], ingredients: [IngredientModel], isUkrainian: Bool
    ) async {
        for i in 0..<products.count {
            var product = products[i]
            var recipe: [RecipeItemModel] = []

            func findIngredient(_ key: String) -> IngredientModel? {
                return ingredients.first { $0.name.lowercased().contains(key.lowercased()) }
            }

            let pName = product.name.lowercased()

            // Coffee base
            if pName.contains("espresso") || pName.contains("еспресо")
                || pName.contains("americano") || pName.contains("американо")
                || pName.contains("latte") || pName.contains("лате")
                || pName.contains("cappuccino") || pName.contains("капучіно")
                || pName.contains("irish") || pName.contains("айріш")
            {
                if let coffee = findIngredient(isUkrainian ? "зерна" : "beans") {
                    recipe.append(
                        RecipeItemModel(
                            id: UUID().uuidString, ingredientId: coffee.id,
                            ingredientName: coffee.name, quantity: 0.018, unit: .kg))
                }
                if let water = findIngredient(isUkrainian ? "вода" : "water") {
                    recipe.append(
                        RecipeItemModel(
                            id: UUID().uuidString, ingredientId: water.id,
                            ingredientName: water.name, quantity: 0.05, unit: .l))
                }
            }

            // Milk based
            if pName.contains("latte") || pName.contains("лате") || pName.contains("cappuccino")
                || pName.contains("капучіно") || pName.contains("cocoa") || pName.contains("какао")
                || pName.contains("chocolate") || pName.contains("шоколад")
            {
                if let milk = findIngredient(isUkrainian ? "молоко" : "milk") {
                    let qty = pName.contains("large") || pName.contains("великий") ? 0.3 : 0.2
                    recipe.append(
                        RecipeItemModel(
                            id: UUID().uuidString, ingredientId: milk.id, ingredientName: milk.name,
                            quantity: qty, unit: .l))
                }
            }

            // Sugar
            if pName.contains("cocoa") || pName.contains("какао") || pName.contains("chocolate")
                || pName.contains("шоколад")
            {
                if let sugar = findIngredient(isUkrainian ? "цукор" : "sugar") {
                    recipe.append(
                        RecipeItemModel(
                            id: UUID().uuidString, ingredientId: sugar.id,
                            ingredientName: sugar.name, quantity: 0.01, unit: .kg))
                }
            }

            // Cups
            if let cup = findIngredient(isUkrainian ? "стакан" : "cup") {
                recipe.append(
                    RecipeItemModel(
                        id: UUID().uuidString, ingredientId: cup.id, ingredientName: cup.name,
                        quantity: 1, unit: .pcs))
            }

            if !recipe.isEmpty {
                product.recipe = recipe
                products[i] = product  // Update in array

                await withCheckedContinuation { continuation in
                    self.saveProductsPrice(productPrice: product) { success in
                        if !success {
                            self.logger.error("Failed to save recipe for: \(product.name)")
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }

    fileprivate func generateDailyActivity(
        days: Int,
        products: [ProductsPriceModel],
        ingredients: inout [IngredientModel],
        types: [TypeModel],
        isUkrainian: Bool,
        manifest: inout DemoDataManifest?
    ) async {
        let calendar = Calendar.current
        for i in 0..<max(1, days) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }

            await processPurchases(date: date, ingredients: &ingredients, manifest: &manifest)
            await processInventoryAdjustments(
                date: date, ingredients: &ingredients, isUkrainian: isUkrainian, manifest: &manifest
            )
            await processOrders(
                date: date, dayIndex: i, products: products, types: types, isUkrainian: isUkrainian,
                manifest: &manifest)
        }
    }

    fileprivate func processPurchases(
        date: Date, ingredients: inout [IngredientModel], manifest: inout DemoDataManifest?
    ) async {
        if !ingredients.isEmpty && Int.random(in: 0...100) < 30 {
            let purchaseCount = Int.random(in: 1...3)
            for _ in 0..<purchaseCount {
                if var randomIngredient = ingredients.randomElement() {
                    let qty = Double(Int.random(in: 5...50))
                    let priceVariation = Double.random(in: 0.9...1.1)
                    let price = (randomIngredient.averageCost * priceVariation).round(to: 2)

                    let purchase = PurchaseModel(
                        id: UUID().uuidString, date: date, ingredientId: randomIngredient.id,
                        quantity: qty, price: price, supplierId: nil
                    )
                    DemoDataManager.shared.addPurchaseId(purchase.id)

                    // Update stock and avg cost
                    let oldTotalValue =
                        randomIngredient.stockQuantity * randomIngredient.averageCost
                    let newPurchaseValue = qty * price
                    let newTotalQuantity = randomIngredient.stockQuantity + qty
                    let newAverageCost =
                        newTotalQuantity > 0
                        ? (oldTotalValue + newPurchaseValue) / newTotalQuantity : price

                    randomIngredient.stockQuantity = newTotalQuantity
                    randomIngredient.averageCost = newAverageCost

                    // Update local array
                    if let index = ingredients.firstIndex(where: { $0.id == randomIngredient.id }) {
                        ingredients[index] = randomIngredient
                    }

                    await withCheckedContinuation { continuation in
                        self.savePurchase(model: purchase) { success in
                            if !success { self.logger.error("Failed to seed purchase") }
                            continuation.resume()
                        }
                    }

                    await withCheckedContinuation { continuation in
                        self.saveIngredient(model: randomIngredient) { success in
                            if !success {
                                self.logger.error("Failed to update ingredient after purchase")
                            }
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }

    fileprivate func processInventoryAdjustments(
        date: Date, ingredients: inout [IngredientModel], isUkrainian: Bool,
        manifest: inout DemoDataManifest?
    ) async {
        if !ingredients.isEmpty && Int.random(in: 0...100) < 10 {
            if let randomIngredient = ingredients.randomElement() {
                let adjustment = InventoryAdjustmentModel(
                    id: UUID().uuidString, date: date, ingredientId: randomIngredient.id,
                    quantityDelta: -1.0, reason: isUkrainian ? "Списання (псування)" : "Spoilage"
                )
                // Note: We don't add adjustment.id here, we wait for the real ID from Firestore

                await withCheckedContinuation { continuation in
                    self.saveInventoryAdjustment(model: adjustment) { id in
                        if let savedId = id {
                            DemoDataManager.shared.addInventoryAdjustmentId(savedId)
                        } else {
                            self.logger.error("Failed to seed inventory adjustment")
                        }
                        continuation.resume()
                    }
                }

                if let index = ingredients.firstIndex(where: { $0.id == randomIngredient.id }) {
                    var ing = ingredients[index]
                    ing.stockQuantity -= 1.0
                    ingredients[index] = ing

                    await withCheckedContinuation { continuation in
                        self.saveIngredient(model: ing) { success in
                            if !success {
                                self.logger.error("Failed to update ingredient after adjustment")
                            }
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }

    fileprivate func processOrders(
        date: Date, dayIndex: Int, products: [ProductsPriceModel], types: [TypeModel],
        isUkrainian: Bool, manifest: inout DemoDataManifest?
    ) async {
        let typeCount = (dayIndex % 3) + 1
        var rotated = types
        let shift = dayIndex % max(1, rotated.count)
        if shift > 0 {
            rotated = Array(rotated[shift...]) + Array(rotated[..<shift])
        }
        let dayTypes = Array(rotated.prefix(typeCount))

        for type in dayTypes {
            let orderId = UUID().uuidString
            let itemCount = 3 + (dayIndex % 3)
            let chosen = Array(products.shuffled().prefix(itemCount))
            var orderItems = [ProductOfOrderModel]()

            for (idx, base) in chosen.enumerated() {
                let qty = 1 + ((dayIndex + idx) % 4)
                let sum = Double(qty) * base.price
                orderItems.append(
                    ProductOfOrderModel(
                        id: UUID().uuidString, orderId: orderId, date: date,
                        name: base.name, quantity: qty, price: base.price, sum: sum
                    ))
            }

            let total = orderItems.reduce(0) { $0 + $1.sum }
            let cash = total * 0.6
            let card = total - cash

            let order = OrderModel(
                id: orderId, date: date, type: type.name, sum: total,
                cash: cash, card: card
            )
            // Note: We don't add orderId to DemoDataManager here because saveOrder will generate a new ID
            // We will add the actual saved ID later

            let savedOrderId: String? = await withCheckedContinuation { continuation in
                self.saveOrder(order: order) { id in
                    if id == nil { self.logger.error("Failed to seed order: \(order.id)") }
                    continuation.resume(returning: id)
                }
            }

            if let savedId = savedOrderId {
                DemoDataManager.shared.addOrderId(savedId)
            }

            let targetOrderId = savedOrderId ?? orderId
            for var item in orderItems {
                item.orderId = targetOrderId
                // Note: We don't add item.id here, we wait for the real ID from Firestore

                await withCheckedContinuation { continuation in
                    self.saveProduct(order: item) { id in
                        if let savedId = id {
                            DemoDataManager.shared.addOrderItemId(savedId)
                        } else {
                            self.logger.error("Failed to seed order item")
                        }
                        continuation.resume()
                    }
                }
            }

            // Opex expenses linked to orders/types logic? No, just daily expenses but calculated here in original code
            // Actually, in original code, expenses loop was inside dayTypes loop.
            // Let's verify logic. Original: `for type in dayTypes { ... process orders ... process expenses }`
            // So for EACH type iteration, it generated expenses.
            await processExpenses(
                date: date, dayIndex: dayIndex,
                loopIndex: dayTypes.firstIndex(where: { $0.id == type.id }) ?? 0,
                count: dayTypes.count, isUkrainian: isUkrainian, manifest: &manifest)
        }
    }

    fileprivate func processExpenses(
        date: Date, dayIndex: Int, loopIndex: Int, count: Int, isUkrainian: Bool,
        manifest: inout DemoDataManifest?
    ) async {
        let costCatalog: [(uk: String, en: String, base: Double)] = [
            ("Оренда", "Rent", 1200),
            ("Комунальні послуги", "Utilities", 300),
            ("Електроенергія", "Electricity", 400),
            ("Вода (офіс)", "Water (office)", 60),
            ("Інтернет", "Internet", 25),
            ("Заробітна плата", "Salary", 800),
            ("Податки", "Taxes", 350),
            ("Маркетинг", "Marketing", 200),
            ("Пакування", "Packaging", 70),
            ("Прибирання", "Cleaning", 50),
            ("Обслуговування обладнання", "Equipment maintenance", 150),
        ]

        let costCount = 2 + ((dayIndex + count) % 3)
        for j in 0..<costCount {
            let entry = costCatalog[(dayIndex + j) % costCatalog.count]
            let name = isUkrainian ? entry.uk : entry.en
            let variance = Double(((dayIndex * 17) + (j * 11)) % 120)
            let amount = (entry.base + variance).rounded(.toNearestOrAwayFromZero)

            let opex = OpexExpenseModel(
                id: UUID().uuidString, date: date, categoryId: isUkrainian ? "Загальні" : "General",
                amount: amount, note: name
            )
            // Note: We don't add opex.id here, we wait for the real ID from Firestore

            await withCheckedContinuation { continuation in
                self.saveOpexExpense(model: opex) { id in
                    if let savedId = id {
                        DemoDataManager.shared.addExpenseId(savedId)
                    } else {
                        self.logger.error("Failed to seed expense: \(name)")
                    }
                    continuation.resume()
                }
            }
        }
    }
    fileprivate func transferCollectionToFIR<RealmModel, DomainModel, FIRModel>(
        collection: String, realmModelType: RealmModel.Type,
        domainModelInit: @escaping (RealmModel) -> DomainModel,
        firModelInit: @escaping (DomainModel) -> FIRModel, completion: @escaping () -> Void
    ) where RealmModel: Object, FIRModel: Encodable {

        DispatchQueue.global().async {
            let realm = try! Realm()
            let realmObjects = realm.objects(realmModelType)
            let internalGroup = DispatchGroup()

            for realmObject in realmObjects {
                internalGroup.enter()
                let domainModel = domainModelInit(realmObject)
                let firModel = firModelInit(domainModel)

                FirestoreDatabaseService.shared.create(firModel: firModel, collection: collection) {
                    result in
                    switch result {
                    case .success(let documentId):
                        self.logger.info(
                            "Created document \(collection) with id - \(String(describing: documentId))"
                        )
                        if collection == FirebaseCollections.orders {
                            let model = domainModel as! OrderModel
                            self.orderIdMap[model.id] = documentId
                        }
                    case .failure(let error):
                        self.logger.error(
                            "Failed to save document \(collection) to Firestore with error: \(error.localizedDescription)"
                        )
                    }
                    internalGroup.leave()
                }
            }

            internalGroup.notify(queue: .global()) {
                completion()
            }
        }
    }

}
