//
//  DemoDataManager.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 24.02.2026.
//

import Foundation
import os.log

struct DemoDataManifest: Codable {
    var typeIds: [String] = []
    var productIds: [String] = []
    var ingredientIds: [String] = []
    var purchaseIds: [String] = []
    var inventoryAdjustmentIds: [String] = []
    var orderIds: [String] = []
    var orderItemIds: [String] = []
    var expenseIds: [String] = []
}

final class DemoDataManager: Loggable {
    static let shared = DemoDataManager()
    private let kManifestKey = "demo_data_manifest"
    private var internalManifest: DemoDataManifest?
    private let queue = DispatchQueue(label: "com.trackmycafe.demodata.queue")

    private init() {
        if let data = UserDefaults.standard.data(forKey: kManifestKey) {
            self.internalManifest = try? JSONDecoder().decode(DemoDataManifest.self, from: data)
        }
        if self.internalManifest == nil {
            self.internalManifest = DemoDataManifest()
        }
    }

    var isDemoDataPresent: Bool {
        return queue.sync {
            guard let manifest = internalManifest else { return false }
            return !manifest.orderIds.isEmpty || !manifest.expenseIds.isEmpty || !manifest.productIds.isEmpty
        }
    }

    private func save() {
        // Must be called inside queue.sync or async
        guard let manifest = internalManifest else { return }
        if let data = try? JSONEncoder().encode(manifest) {
            UserDefaults.standard.set(data, forKey: kManifestKey)
        }
    }

    func getManifest() -> DemoDataManifest? {
        return queue.sync { internalManifest }
    }

    func clearManifest() {
        queue.sync {
            internalManifest = DemoDataManifest()
            UserDefaults.standard.removeObject(forKey: kManifestKey)
        }
    }

    // MARK: - Batch Saving
    func saveCurrentManifest() {
        queue.sync {
            save()
        }
    }

    // MARK: - Incremental Saving
    func addTypeId(_ id: String) {
        queue.sync {
            internalManifest?.typeIds.append(id)
        }
    }

    func addProductId(_ id: String) {
        queue.sync {
            internalManifest?.productIds.append(id)
        }
    }

    func addIngredientId(_ id: String) {
        queue.sync {
            internalManifest?.ingredientIds.append(id)
        }
    }

    func addPurchaseId(_ id: String) {
        queue.sync {
            internalManifest?.purchaseIds.append(id)
        }
    }

    func addInventoryAdjustmentId(_ id: String) {
        queue.sync {
            internalManifest?.inventoryAdjustmentIds.append(id)
        }
    }

    func addOrderId(_ id: String) {
        queue.sync {
            internalManifest?.orderIds.append(id)
        }
    }

    func addOrderItemId(_ id: String) {
        queue.sync {
            internalManifest?.orderItemIds.append(id)
        }
    }

    func addExpenseId(_ id: String) {
        queue.sync {
            internalManifest?.expenseIds.append(id)
        }
    }

    func deleteDemoData(completion: @escaping (Bool) -> Void) {
        guard let manifest = getManifest() else {
            completion(true)
            return
        }

        Task {
            logger.info("Deleting demo data with manifest items:")
            logger.info("- Orders: \(manifest.orderIds.count)")
            logger.info("- Expenses: \(manifest.expenseIds.count)")
            logger.info("- Products: \(manifest.productIds.count)")
            // Delete Order Items
            await deleteBatch(collection: FirebaseCollections.productOfOrders, ids: manifest.orderItemIds)
            logger.info("Deleted \(manifest.orderItemIds.count) order items")

            // Delete Orders
            await deleteBatch(collection: FirebaseCollections.orders, ids: manifest.orderIds)
            logger.info("Deleted \(manifest.orderIds.count) orders")

            // Delete Expenses
            await deleteBatch(collection: FirebaseCollections.opexExpenses, ids: manifest.expenseIds)
            logger.info("Deleted \(manifest.expenseIds.count) expenses")

            // Delete Purchases
            await deleteBatch(collection: FirebaseCollections.purchases, ids: manifest.purchaseIds)
            logger.info("Deleted \(manifest.purchaseIds.count) purchases")

            // Delete Inventory Adjustments
            await deleteBatch(collection: FirebaseCollections.inventoryAdjustments, ids: manifest.inventoryAdjustmentIds)
            logger.info("Deleted \(manifest.inventoryAdjustmentIds.count) adjustments")

            // Delete Products
            await deleteBatch(collection: FirebaseCollections.productsPrice, ids: manifest.productIds)
            logger.info("Deleted \(manifest.productIds.count) products")

            // Delete Ingredients
            await deleteBatch(collection: FirebaseCollections.ingredients, ids: manifest.ingredientIds)
            logger.info("Deleted \(manifest.ingredientIds.count) ingredients")

            // Delete Types
            await deleteBatch(collection: FirebaseCollections.types, ids: manifest.typeIds)
            logger.info("Deleted \(manifest.typeIds.count) types")

            clearManifest()
            await MainActor.run {
                completion(true)
            }
        }
    }

    private func deleteBatch(collection: String, ids: [String]) async {
        await withCheckedContinuation { continuation in
            FirestoreDatabaseService.shared.deleteDocuments(collection: collection, ids: ids) { _ in
                continuation.resume()
            }
        }
    }
}
