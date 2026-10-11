//
//  Repository.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation
import os.log

// swiftlint:disable file_length
// Domain seeding + CRUD helpers intentionally live in one file; split in a follow-up.
class DomainDatabaseService: DomainDB {

    static let shared = DomainDatabaseService()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!, category: "DomainDatabaseService")
    private let orderSnapshotRepairService = OrderSnapshotRepairService()

    // Метод для перевірки, чи включений режим онлайн
    // private func isOnlineModeEnabled() -> Bool {
    //     return SettingsManager.shared.loadOnline()
    // }

    private func normalizedDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    // MARK: - Ingredient Operations

    func fetchIngredients() async -> [IngredientModel] {
        do {
            let firModels = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.ingredients, firModel: FIRIngredientModel.self)
            return firModels.map { IngredientModel(firebaseModel: $0.1) }
        } catch {
            logger.error(
                "Error fetching ingredients from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    func saveIngredient(model: IngredientModel) async -> Bool {
        let firModel = FIRIngredientModel(dataModel: model)
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: firModel, collection: FirebaseCollections.ingredients,
                documentId: model.id)
            return true
        } catch {
            logger.error(
                "Failed to save ingredient to Firestore: \(error.localizedDescription)")
            return false
        }
    }

    func deleteIngredient(model: IngredientModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.ingredients, documentId: model.id)
            return true
        } catch {
            logger.error("Failed to delete ingredient from Firestore: \(error)")
            return false
        }
    }

    // MARK: - New Methods (Step 4 & Purchase)

    func fetchIngredient(byId id: String) async -> IngredientModel? {
        do {
            let firModel = try await FirestoreDatabaseService.shared.fetchObjectById(
                ofType: FIRIngredientModel.self, collection: FirebaseCollections.ingredients,
                id: id)
            return IngredientModel(firebaseModel: firModel)
        } catch {
            logger.error(
                "Error fetching ingredient from Firestore: \(error.localizedDescription)")
            return nil
        }
    }

    // Purchases
    func fetchPurchases() async -> [PurchaseModel] {
        do {
            let firPurchases = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.purchases, firModel: FIRPurchaseModel.self)
            return firPurchases.map { PurchaseModel(firebaseModel: $0.1) }
        } catch {
            logger.error(
                "Error fetching purchases from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    func savePurchase(model: PurchaseModel) async -> Bool {
        let firModel = FIRPurchaseModel(dataModel: model)
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: firModel, collection: FirebaseCollections.purchases,
                documentId: model.id)
            logger.info("Purchase saved to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to save purchase to Firestore with error: \(error.localizedDescription)")
            return false
        }
    }

    func deletePurchase(model: PurchaseModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.purchases, documentId: model.id)
            logger.info("Purchase deleted from Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to delete purchase from Firestore with error: \(error.localizedDescription)"
            )
            return false
        }
    }

    // Recipes
    func fetchRecipe(forProductId productId: String) async -> [RecipeItemModel] {
        do {
            let product = try await FirestoreDatabaseService.shared.fetchObjectById(
                ofType: FIRProductsPriceModel.self,
                collection: FirebaseCollections.productsPrice,
                id: productId)
            return product.recipe.map { RecipeItemModel(firebaseModel: $0) }
        } catch {
            logger.error("Error fetching recipe from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Product Operations

    func updateProduct(
        model: ProductOfOrderModel, date: Date, name: String, quantity: Int, price: Double,
        sum: Double
    ) async {
        guard !model.id.isEmpty else {
            logger.warning(
                "updateProduct called with empty documentId for product \(name), using saveProduct instead"
            )
            var product = model
            product.date = date
            product.name = name
            product.quantity = quantity
            product.price = price
            product.sum = sum
            let id = await saveProduct(order: product)
            if id == nil {
                logger.error("Fallback saveProduct failed for product \(name)")
            }
            return
        }

        var updatedModel = FIRProductModel(dataModel: model)
        updatedModel.date = date
        updatedModel.name = name
        updatedModel.quantity = quantity
        updatedModel.price = price
        updatedModel.amount = sum

        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: updatedModel, collection: FirebaseCollections.productOfOrders,
                documentId: model.id)
            logger.info("Order product updated successfully in Firestore database")
        } catch {
            logger.error(
                "Failed to update order product in Firestore database: \(error.localizedDescription)"
            )
        }
    }

    func fetchProduct(forDate date: Date) async -> [ProductOfOrderModel] {
        do {
            let firProducts = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self)
            return firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
        } catch {
            logger.error(
                "Error fetching products from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    func fetchProduct(forDate date: Date, withName name: String) async -> ProductOfOrderModel? {
        let allProducts = await fetchProduct(forDate: date)
        return allProducts.first { $0.date == date && $0.name == name }
    }

    func fetchProduct(withOrderId id: String) async -> [ProductOfOrderModel] {
        guard !id.isEmpty else { return [] }

        do {
            let firProducts = try await FirestoreDatabaseService.shared.readWhere(
                collection: FirebaseCollections.productOfOrders,
                firModel: FIRProductModel.self,
                equalTo: ["orderId": id])
            let products = firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }

            guard let order = await fetchOrders(forId: id) else {
                return products
            }

            let repairedSnapshot = orderSnapshotRepairService.repair(
                order: order, products: products)
            await persistRepairedSnapshotIfNeeded(repairedSnapshot)
            return repairedSnapshot.products
        } catch {
            logger.error(
                "Error fetching products from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    func fetchOrderItems(withOrderId id: String) async -> [OrderItemModel] {
        let products = await fetchProduct(withOrderId: id)
        return products.map(\.orderItemSnapshot)
    }

    func fetchProductsOfOrders(from startDate: Date, to endDate: Date) async
        -> [ProductOfOrderModel] {
        do {
            let firProducts = try await FirestoreDatabaseService.shared.readWhere(
                collection: FirebaseCollections.productOfOrders,
                firModel: FIRProductModel.self,
                equalTo: [:],
                orderedBy: "date",
                startAt: startDate,
                endAt: endDate)
            return firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
        } catch {
            logger.error(
                "Error fetching products in date range from Firestore: \(error.localizedDescription)"
            )
            return []
        }
    }

    func saveProduct(order: ProductOfOrderModel) async -> String? {
        if order.id.isEmpty {
            do {
                let id = try await FirestoreDatabaseService.shared.create(
                    firModel: FIRProductModel(dataModel: order),
                    collection: FirebaseCollections.productOfOrders)
                logger.info(
                    "Order product created in Firestore successfully with ID: \(id)")
                return id
            } catch {
                logger.error(
                    "Failed to create order product in Firestore with error: \(error.localizedDescription)"
                )
                return nil
            }
        } else {
            do {
                try await FirestoreDatabaseService.shared.update(
                    firModel: FIRProductModel(dataModel: order),
                    collection: FirebaseCollections.productOfOrders,
                    documentId: order.id)
                logger.info(
                    "Order product updated in Firestore successfully with ID: \(order.id)")
                return order.id
            } catch {
                logger.error(
                    "Failed to update order product in Firestore with error: \(error.localizedDescription)"
                )
                return nil
            }
        }
    }

    func deleteProduct(order: ProductOfOrderModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.productOfOrders, documentId: order.id)
            logger.info("Order product deleted to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to delete order product to Firestore with error: \(error.localizedDescription)"
            )
            return false
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
        totalCost: Double,
        note: String?
    ) async {
        let updatedOrder = OrderModel(
            id: model.id,
            date: date,
            type: type,
            sum: total,
            cash: cashAmount,
            card: cardAmount,
            totalCost: totalCost,
            inventoryTracking: model.inventoryTracking,
            note: note
        )
        _ = await updateOrder(updatedOrder)
    }

    func updateOrder(_ order: OrderModel) async -> Bool {
        let updatedModel = FIROrderModel(dataModel: order)
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: updatedModel, collection: FirebaseCollections.orders, documentId: order.id
            )
            logger.info("Order updated successfully in Firestore database")
            return true
        } catch {
            logger.error(
                "Failed to update order in Firestore database: \(error.localizedDescription)")
            return false
        }
    }

    func fetchOrders() async -> [OrderModel] {
        async let firOrders = getFirOrders()
        async let firProducts = getFirOrderProducts()

        let (ordersResult, productsResult) = await (firOrders, firProducts)

        do {
            let firOrders = try ordersResult.get()
            let fetchedOrders = firOrders.map { OrderModel(firebaseModel: $1) }
            let fetchedProducts: [ProductOfOrderModel]
            do {
                fetchedProducts = try productsResult.get().map {
                    ProductOfOrderModel(firebaseModel: $0.1)
                }
            } catch {
                logger.error(
                    "Error fetching order items from Firestore: \(error.localizedDescription)")
                fetchedProducts = []
            }

            let productsByOrderId = Dictionary(grouping: fetchedProducts) { $0.orderId }
            var repairedOrders: [OrderModel] = []
            repairedOrders.reserveCapacity(fetchedOrders.count)
            for order in fetchedOrders {
                let repairResult = orderSnapshotRepairService.repair(
                    order: order,
                    products: productsByOrderId[order.id] ?? [])
                await persistRepairedSnapshotIfNeeded(repairResult)
                repairedOrders.append(repairResult.order)
            }
            return repairedOrders
        } catch {
            logger.error(
                "Error fetching orders from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    private func getFirOrders() async -> Result<[(String, FIROrderModel)], Error> {
        do {
            let orders = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.orders, firModel: FIROrderModel.self)
            return .success(orders)
        } catch {
            return .failure(error)
        }
    }

    private func getFirOrderProducts() async -> Result<[(String, FIRProductModel)], Error> {
        do {
            let products = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self)
            return .success(products)
        } catch {
            return .failure(error)
        }
    }

    func fetchSectionsOfOrders() async -> [(date: Date, items: [OrderModel])] {
        let orders = await fetchOrders()
        let calendar = Calendar.current
        let groupedOrders = Dictionary(
            grouping: orders,
            by: { order -> Date in
                let dateComponents = calendar.dateComponents(
                    [.year, .month, .day], from: order.date)
                return calendar.date(from: dateComponents)
                    ?? calendar.startOfDay(for: order.date)
            })
        return groupedOrders.map { (date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    func fetchOrders(forId id: String) async -> OrderModel? {
        do {
            let firOrder = try await FirestoreDatabaseService.shared.fetchObjectById(
                ofType: FIROrderModel.self,
                collection: FirebaseCollections.orders,
                id: id)
            return OrderModel(firebaseModel: firOrder)
        } catch {
            logger.error(
                "Error fetching order by id from Firestore: \(error.localizedDescription)")
            return nil
        }
    }

    func saveOrder(order: OrderModel) async -> String? {
        do {
            let documentId = try await FirestoreDatabaseService.shared.create(
                firModel: FIROrderModel(dataModel: order), collection: FirebaseCollections.orders)
            logger.info("Order saved to Firestore successfully")
            return documentId
        } catch {
            logger.error(
                "Failed to save order to Firestore with error: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteOrder(order: OrderModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.orders, documentId: order.id)
            logger.info("Order deleted to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to delete order to Firestore with error: \(error.localizedDescription)")
            return false
        }
    }

    func hasAnyOrderWithInventoryTracking() async -> Bool {
        do {
            let list = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.orders,
                firModel: FIROrderModel.self)
            return list.contains { ($0.1.inventoryTracking ?? false) == true }
        } catch {
            return false
        }
    }

    // MARK: - ProductsPrice Operations

    func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double) async {
        var updatedModel = FIRProductsPriceModel(dataModel: model)
        updatedModel.name = name
        updatedModel.price = price
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: updatedModel, collection: FirebaseCollections.productsPrice,
                documentId: model.id)
            logger.info("Product price updated successfully in Firestore database")
        } catch {
            logger.error(
                "Failed to update product price in Firestore database: \(error.localizedDescription)"
            )
        }
    }

    func fetchProductsPrice() async -> [ProductsPriceModel] {
        do {
            let firProducts = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.productsPrice,
                firModel: FIRProductsPriceModel.self)
            return firProducts.map { ProductsPriceModel(firebaseModel: $1) }
        } catch {
            logger.error(
                "Error fetching products from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    func saveProductsPrice(productPrice: ProductsPriceModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: FIRProductsPriceModel(dataModel: productPrice),
                collection: FirebaseCollections.productsPrice,
                documentId: productPrice.id)
            logger.info("Product price saved to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to save product price to Firestore with error: \(error.localizedDescription)"
            )
            return false
        }
    }

    func deleteProductsPrice(model: ProductsPriceModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.productsPrice, documentId: model.id)
            logger.info("productsPrice deleted to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to productsPrice order to Firestore with error: \(error.localizedDescription)"
            )
            return false
        }
    }

    // MARK: - Product Categories Operations

    func fetchProductCategories() async -> [ProductCategoryModel] {
        do {
            let firCategories = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.productCategories,
                firModel: FIRProductCategoryModel.self)
            let categories = firCategories.map { ProductCategoryModel(firebaseModel: $1) }
            return categories.sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            logger.error(
                "Error fetching product categories from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    func saveProductCategory(model: ProductCategoryModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: FIRProductCategoryModel(dataModel: model),
                collection: FirebaseCollections.productCategories,
                documentId: model.id)
            logger.info("Product category saved to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to save product category to Firestore with error: \(error.localizedDescription)"
            )
            return false
        }
    }

    func deleteProductCategory(model: ProductCategoryModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.productCategories,
                documentId: model.id)
            logger.info("Product category deleted in Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to delete product category in Firestore with error: \(error.localizedDescription)"
            )
            return false
        }
    }

    // MARK: - Cost Operations (Deprecated, use Opex Operations)

    // MARK: - Type Operations

    func updateType(model: TypeModel, type: String) async {
        var updatedModel = FIRTypeModel(dataModel: model)
        updatedModel.name = type
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: updatedModel, collection: FirebaseCollections.types,
                documentId: model.id)
            logger.info("Type updated successfully in Firestore database")
        } catch {
            logger.error(
                "Failed to update type in Firestore database: \(error.localizedDescription)")
        }
    }

    func fetchTypes() async -> [TypeModel] {
        do {
            let firTypes = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.types, firModel: FIRTypeModel.self)
            return firTypes.map { TypeModel(firebaseModel: $1) }
        } catch {
            logger.error(
                "Error fetching types from Firestore: \(error.localizedDescription)")
            return []
        }
    }

    func saveType(model: TypeModel) async -> Bool {
        do {
            _ = try await FirestoreDatabaseService.shared.create(
                firModel: FIRTypeModel(dataModel: model), collection: FirebaseCollections.types)
            logger.info("Types saved to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to save Types to Firestore with error: \(error.localizedDescription)")
            return false
        }
    }

    func setDefaultType(model: TypeModel, isDefault: Bool) async {
        do {
            let firTypes = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.types, firModel: FIRTypeModel.self)
            let types = firTypes.map { TypeModel(firebaseModel: $1) }
            for type in types {
                var updated = FIRTypeModel(dataModel: type)
                updated.isDefault = (type.id == model.id) ? isDefault : false
                _ = try? await FirestoreDatabaseService.shared.update(
                    firModel: updated, collection: FirebaseCollections.types,
                    documentId: type.id)
            }
            logger.info("Default type updated in Firestore")
        } catch {
            logger.error(
                "Failed to update default type in Firestore: \(error.localizedDescription)")
        }
    }

    func deleteType(model: TypeModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.types, documentId: model.id)
            logger.info("Types deleted to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to delete types order to Firestore with error: \(error.localizedDescription)"
            )
            return false
        }
    }

    // MARK: - Inventory Adjustment Operations

    func saveInventoryAdjustment(model: InventoryAdjustmentModel) async -> String? {
        let firModel = FIRInventoryAdjustmentModel(dataModel: model)
        do {
            let id = try await FirestoreDatabaseService.shared.create(
                firModel: firModel, collection: FirebaseCollections.inventoryAdjustments)
            logger.info("Inventory adjustment saved to Firestore successfully")
            return id
        } catch {
            logger.error(
                "Failed to save inventory adjustment: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchInventoryAdjustments() async -> [InventoryAdjustmentModel] {
        do {
            let firModels = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.inventoryAdjustments,
                firModel: FIRInventoryAdjustmentModel.self)
            return firModels.map {
                InventoryAdjustmentModel(
                    id: $0.1.id ?? "",
                    date: $0.1.date,
                    ingredientId: $0.1.ingredientId,
                    quantityDelta: $0.1.quantityDelta,
                    reason: $0.1.reason,
                    source: InventoryAdjustmentSource(
                        rawValue: $0.1.source ?? InventoryAdjustmentSource.manual.rawValue
                    ) ?? .manual,
                    bulkSessionId: $0.1.bulkSessionId,
                    userId: $0.1.userId
                )
            }
        } catch {
            logger.error(
                "Error fetching inventory adjustments: \(error.localizedDescription)")
            return []
        }
    }

    func fetchInventoryAdjustments(
        from startDate: Date? = nil,
        to endDate: Date? = nil,
        ingredientId: String? = nil,
        bulkSessionId: String? = nil
    ) async -> [InventoryAdjustmentModel] {
        var filters: [String: Any] = [:]
        if let ingredientId { filters["ingredientId"] = ingredientId }
        if let bulkSessionId { filters["bulkSessionId"] = bulkSessionId }

        let hasDateRange = startDate != nil || endDate != nil
        let orderedBy: String? = hasDateRange ? "date" : nil

        do {
            let firModels = try await FirestoreDatabaseService.shared.readWhere(
                collection: FirebaseCollections.inventoryAdjustments,
                firModel: FIRInventoryAdjustmentModel.self,
                equalTo: filters,
                orderedBy: orderedBy,
                startAt: startDate,
                endAt: endDate)
            return firModels.map {
                InventoryAdjustmentModel(
                    id: $0.1.id ?? "",
                    date: $0.1.date,
                    ingredientId: $0.1.ingredientId,
                    quantityDelta: $0.1.quantityDelta,
                    reason: $0.1.reason,
                    source: InventoryAdjustmentSource(
                        rawValue: $0.1.source ?? InventoryAdjustmentSource.manual.rawValue
                    ) ?? .manual,
                    bulkSessionId: $0.1.bulkSessionId,
                    userId: $0.1.userId
                )
            }
            .sorted { $0.date > $1.date }
        } catch {
            logger.error(
                "Error fetching filtered inventory adjustments: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Opex Operations

    func saveOpexExpense(model: OpexExpenseModel) async -> String? {
        let firModel = FIROpexExpenseModel(dataModel: model)
        do {
            let id = try await FirestoreDatabaseService.shared.create(
                firModel: firModel, collection: FirebaseCollections.opexExpenses)
            logger.info("Opex expense saved to Firestore successfully with ID: \(id)")
            return id
        } catch {
            logger.error("Failed to save opex expense: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchOpexExpenses() async -> [OpexExpenseModel] {
        do {
            let firModels = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.opexExpenses, firModel: FIROpexExpenseModel.self)
            return firModels.map {
                OpexExpenseModel(
                    id: $0.1.id ?? "", date: $0.1.date, categoryId: $0.1.categoryId,
                    amount: $0.1.amount, paymentAccount: $0.1.paymentAccount, note: $0.1.note)
            }
        } catch {
            logger.error("Error fetching opex expenses: \(error.localizedDescription)")
            return []
        }
    }

    func updateOpexExpense(model: OpexExpenseModel) async {
        let firModel = FIROpexExpenseModel(dataModel: model)
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: firModel, collection: FirebaseCollections.opexExpenses,
                documentId: model.id)
            logger.info("Opex expense updated successfully")
        } catch {
            logger.error("Failed to update opex expense: \(error.localizedDescription)")
        }
    }

    func deleteOpexExpense(model: OpexExpenseModel) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: FirebaseCollections.opexExpenses, documentId: model.id)
            logger.info("Opex expense deleted successfully")
            return true
        } catch {
            logger.error("Failed to delete opex expense: \(error.localizedDescription)")
            return false
        }
    }

    func fetchSectionsOfOpexExpenses() async -> [(date: Date, items: [OpexExpenseModel])] {
        let expenses = await fetchOpexExpenses()
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { expense in
            let components = calendar.dateComponents([.year, .month, .day], from: expense.date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: expense.date)
        }
        return grouped.map { (date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Journal Entries

    func saveJournalEntry(model: JournalEntryModel) async -> String? {
        let firModel = FIRJournalEntryModel(dataModel: model)
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: firModel,
                collection: FirebaseCollections.journalEntries,
                documentId: model.id)
            logger.info("Journal entry saved to Firestore successfully")
            return model.id
        } catch {
            logger.error(
                "Failed to save journal entry to Firestore: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchJournalEntries() async -> [JournalEntryModel] {
        do {
            let firModels = try await FirestoreDatabaseService.shared.read(
                collection: FirebaseCollections.journalEntries,
                firModel: FIRJournalEntryModel.self)
            return
                firModels
                .map { JournalEntryModel(firebaseModel: $0.1) }
                .sorted { $0.date < $1.date }
        } catch {
            logger.error("Error fetching journal entries: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Daily Balances

    func saveDailyBalance(model: DailyBalanceModel) async -> Bool {
        let firModel = FIRDailyBalanceModel(dataModel: model)
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: firModel,
                collection: FirebaseCollections.dailyBalances,
                documentId: model.id)
            logger.info("Daily balance saved to Firestore successfully")
            return true
        } catch {
            logger.error(
                "Failed to save daily balance to Firestore: \(error.localizedDescription)")
            return false
        }
    }

    func fetchDailyBalance(
        forAccount account: PaymentAccount,
        date: Date
    ) async -> DailyBalanceModel? {
        let normalizedDate = normalizedDay(date)
        let documentId = DailyBalanceModel.makeDocumentId(for: account, date: normalizedDate)

        do {
            let firModel = try await FirestoreDatabaseService.shared.fetchObjectById(
                ofType: FIRDailyBalanceModel.self,
                collection: FirebaseCollections.dailyBalances,
                id: documentId)
            return DailyBalanceModel(firebaseModel: firModel)
        } catch {
            logger.error("Error fetching daily balance: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchDailyBalances(
        forAccount account: PaymentAccount,
        from startDate: Date,
        to endDate: Date
    ) async -> [DailyBalanceModel] {
        let normalizedStartDate = normalizedDay(startDate)
        let normalizedEndDate = normalizedDay(endDate)
        let lowerBound = min(normalizedStartDate, normalizedEndDate)
        let upperBound = max(normalizedStartDate, normalizedEndDate)

        let startId = DailyBalanceModel.makeDocumentId(for: account, date: lowerBound)
        let endId = DailyBalanceModel.makeDocumentId(for: account, date: upperBound)

        do {
            let firModels = try await FirestoreDatabaseService.shared.readDocumentIdRange(
                collection: FirebaseCollections.dailyBalances,
                firModel: FIRDailyBalanceModel.self,
                startId: startId,
                endId: endId)
            return
                firModels
                .map { DailyBalanceModel(firebaseModel: $0.1) }
                .filter { balance in
                    balance.date >= lowerBound && balance.date <= upperBound
                }
                .sorted { lhs, rhs in
                    lhs.date < rhs.date
                }
        } catch {
            logger.error(
                "Error fetching daily balances for account \(account.rawValue), range \(lowerBound)–\(upperBound)"
            )
            return []
        }
    }

    // MARK: - delete Operations

    func deleteActiveDatabaseData() async -> Bool {
        let success = await FirestoreDatabaseService.shared.deleteAllData()
        if success {
            logger.log("All data deleted successfully from Firestore database")
            DemoDataManager.shared.clearManifest()
        } else {
            logger.log("Failed to delete data from Firestore database")
        }
        return success
    }

    // MARK: - Generic Delete Operation
    func delete(collection: String, documentId: String) async -> Bool {
        do {
            try await FirestoreDatabaseService.shared.delete(
                collection: collection, documentId: documentId)
            logger.info("Document \(documentId) deleted from \(collection) successfully")
            return true
        } catch {
            logger.error(
                "Failed to delete document \(documentId) from \(collection): \(error)")
            return false
        }
    }

    // MARK: - general Operations

    var orderIdMap: [String: String] = [:]

    @MainActor
    func seedTestData(forDays days: Int) async {
        await cleanDatabase()
        var manifest: DemoDataManifest?
        await seedDemoData(days: days, manifest: &manifest)
    }

    @MainActor
    func seedUserDemoData() async {
        // Clear old manifest if exists before starting new seeding
        DemoDataManager.shared.clearManifest()

        var manifest: DemoDataManifest?  // We don't use this local manifest anymore for persistence, but keep signature
        await seedDemoData(days: 14, manifest: &manifest)
    }

    @MainActor
    private func seedDemoData(days: Int, manifest: inout DemoDataManifest?) async {
        // Wait a bit to ensure Firestore processes deletions
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        let isUkrainian = Locale.isCurrentLanguageUkrainian

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

extension DomainDatabaseService {
    fileprivate func persistRepairedSnapshotIfNeeded(_ snapshot: OrderSnapshotRepairResult) async {
        if snapshot.didRepairOrder {
            let success = await updateOrder(snapshot.order)
            if !success {
                logger.error(
                    "Failed to persist repaired order snapshot: \(snapshot.order.id)")
            }
        }

        if snapshot.didRepairProducts {
            for product in snapshot.products {
                await persistRepairedProduct(product)
            }
        }
    }

    fileprivate func persistRepairedProduct(_ product: ProductOfOrderModel) async {
        do {
            try await FirestoreDatabaseService.shared.update(
                firModel: FIRProductModel(dataModel: product),
                collection: FirebaseCollections.productOfOrders,
                documentId: product.id)
        } catch {
            logger.error(
                "Failed to persist repaired order item snapshot: \(error.localizedDescription)")
        }
    }
}
// MARK: - Seeding Helpers
extension DomainDatabaseService {

    fileprivate func cleanDatabase() async {
        _ = await deleteActiveDatabaseData()
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

        for type in types {
            DemoDataManager.shared.addTypeId(type.id)
            let success = await saveType(model: type)
            if !success { logger.error("Failed to seed type: \(type.name)") }
        }
        return types
    }

    fileprivate func seedProducts(isUkrainian: Bool, manifest: inout DemoDataManifest?) async
        -> [ProductsPriceModel] {
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

        for product in products {
            DemoDataManager.shared.addProductId(product.id)
            let success = await saveProductsPrice(productPrice: product)
            if !success { logger.error("Failed to seed product: \(product.name)") }
        }
        return products
    }

    fileprivate func seedIngredients(isUkrainian: Bool, manifest: inout DemoDataManifest?) async
        -> [IngredientModel] {
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

            let success = await saveIngredient(model: ingredient)
            if !success { logger.error("Failed to seed ingredient: \(name)") }
        }
        return createdIngredients
    }

    fileprivate func assignRecipes(
        to products: inout [ProductsPriceModel], ingredients: [IngredientModel], isUkrainian: Bool
    ) async {
        for i in 0..<products.count {
            var product = products[i]
            let recipe = buildDemoRecipe(
                productName: product.name, ingredients: ingredients, isUkrainian: isUkrainian
            )

            if !recipe.isEmpty {
                product.recipe = recipe
                products[i] = product  // Update in array

                let success = await saveProductsPrice(productPrice: product)
                if !success {
                    logger.error("Failed to save recipe for: \(product.name)")
                }
            }
        }
    }

    private func buildDemoRecipe(
        productName: String, ingredients: [IngredientModel], isUkrainian: Bool
    ) -> [RecipeItemModel] {
        var recipe: [RecipeItemModel] = []
        let pName = productName.lowercased()

        func findIngredient(_ key: String) -> IngredientModel? {
            ingredients.first { $0.name.lowercased().contains(key.lowercased()) }
        }

        // Coffee base
        if pName.contains("espresso") || pName.contains("еспресо")
            || pName.contains("americano") || pName.contains("американо")
            || pName.contains("latte") || pName.contains("лате")
            || pName.contains("cappuccino") || pName.contains("капучіно")
            || pName.contains("irish") || pName.contains("айріш") {
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
            || pName.contains("chocolate") || pName.contains("шоколад") {
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
            || pName.contains("шоколад") {
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

        return recipe
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

                    let purchaseSuccess = await savePurchase(model: purchase)
                    if !purchaseSuccess { logger.error("Failed to seed purchase") }

                    let ingredientSuccess = await saveIngredient(model: randomIngredient)
                    if !ingredientSuccess {
                        logger.error("Failed to update ingredient after purchase")
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
                    quantityDelta: -1.0, reason: R.string.global.reasonSpoilage()
                )
                // * Note: We don't add adjustment.id here, we wait for the real ID from Firestore

                let savedId = await saveInventoryAdjustment(model: adjustment)
                if let savedId = savedId {
                    DemoDataManager.shared.addInventoryAdjustmentId(savedId)
                } else {
                    logger.error("Failed to seed inventory adjustment")
                }

                if let index = ingredients.firstIndex(where: { $0.id == randomIngredient.id }) {
                    var ing = ingredients[index]
                    ing.stockQuantity -= 1.0
                    ingredients[index] = ing

                    let success = await saveIngredient(model: ing)
                    if !success {
                        logger.error("Failed to update ingredient after adjustment")
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

            let savedOrderId = await saveOrder(order: order)
            if savedOrderId == nil { logger.error("Failed to seed order: \(order.id)") }

            if let savedId = savedOrderId {
                DemoDataManager.shared.addOrderId(savedId)
            }

            let targetOrderId = savedOrderId ?? orderId
            for var item in orderItems {
                item.orderId = targetOrderId
                // Note: We don't add item.id here, we wait for the real ID from Firestore

                let savedId = await saveProduct(order: item)
                if let savedId = savedId {
                    DemoDataManager.shared.addOrderItemId(savedId)
                } else {
                    logger.error("Failed to seed order item")
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
                id: UUID().uuidString, date: date, categoryId: R.string.global.categoryGeneral(),
                amount: amount, note: name
            )
            // Note: We don't add opex.id here, we wait for the real ID from Firestore

            let savedId = await saveOpexExpense(model: opex)
            if let savedId = savedId {
                DemoDataManager.shared.addExpenseId(savedId)
            } else {
                logger.error("Failed to seed expense: \(name)")
            }
        }
    }

}
