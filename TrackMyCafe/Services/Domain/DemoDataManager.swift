//
//  DemoDataManager.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 24.02.2026.
//

import Foundation

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

final class DemoDataManager {
    static let shared = DemoDataManager()
    private let kManifestKey = "demo_data_manifest"

    var isDemoDataPresent: Bool {
        return UserDefaults.standard.data(forKey: kManifestKey) != nil
    }

    func saveManifest(_ manifest: DemoDataManifest) {
        if let data = try? JSONEncoder().encode(manifest) {
            UserDefaults.standard.set(data, forKey: kManifestKey)
        }
    }

    func getManifest() -> DemoDataManifest? {
        guard let data = UserDefaults.standard.data(forKey: kManifestKey) else { return nil }
        return try? JSONDecoder().decode(DemoDataManifest.self, from: data)
    }

    func clearManifest() {
        UserDefaults.standard.removeObject(forKey: kManifestKey)
    }

    // MARK: - Incremental Saving
    func addTypeId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.typeIds.append(id)
        saveManifest(manifest)
    }

    func addProductId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.productIds.append(id)
        saveManifest(manifest)
    }

    func addIngredientId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.ingredientIds.append(id)
        saveManifest(manifest)
    }

    func addPurchaseId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.purchaseIds.append(id)
        saveManifest(manifest)
    }

    func addInventoryAdjustmentId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.inventoryAdjustmentIds.append(id)
        saveManifest(manifest)
    }

    func addOrderId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.orderIds.append(id)
        saveManifest(manifest)
    }

    func addOrderItemId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.orderItemIds.append(id)
        saveManifest(manifest)
    }

    func addExpenseId(_ id: String) {
        var manifest = getManifest() ?? DemoDataManifest()
        manifest.expenseIds.append(id)
        saveManifest(manifest)
    }

    func deleteDemoData(completion: @escaping (Bool) -> Void) {
        guard let manifest = getManifest() else {
            completion(true)
            return
        }

        Task {
            print("Deleting demo data...")
            // Delete Order Items
            for id in manifest.orderItemIds {
                await delete(collection: FirebaseCollections.productOfOrders, id: id)
            }
            print("Deleted \(manifest.orderItemIds.count) order items")

            // Delete Orders
            for id in manifest.orderIds {
                await delete(collection: FirebaseCollections.orders, id: id)
            }
            print("Deleted \(manifest.orderIds.count) orders")

            // Delete Expenses
            for id in manifest.expenseIds {
                await delete(collection: FirebaseCollections.opexExpenses, id: id)
            }
            print("Deleted \(manifest.expenseIds.count) expenses")

            // Delete Purchases
            for id in manifest.purchaseIds {
                await delete(collection: FirebaseCollections.purchases, id: id)
            }
            print("Deleted \(manifest.purchaseIds.count) purchases")

            // Delete Inventory Adjustments
            for id in manifest.inventoryAdjustmentIds {
                await delete(collection: FirebaseCollections.inventoryAdjustments, id: id)
            }
            print("Deleted \(manifest.inventoryAdjustmentIds.count) adjustments")

            // Delete Products
            for id in manifest.productIds {
                await delete(collection: FirebaseCollections.productsPrice, id: id)
            }
            print("Deleted \(manifest.productIds.count) products")

            // Delete Ingredients
            for id in manifest.ingredientIds {
                await delete(collection: FirebaseCollections.ingredients, id: id)
            }
            print("Deleted \(manifest.ingredientIds.count) ingredients")

            // Delete Types
            for id in manifest.typeIds {
                await delete(collection: FirebaseCollections.types, id: id)
            }
            print("Deleted \(manifest.typeIds.count) types")

            clearManifest()
            await MainActor.run {
                completion(true)
            }
        }
    }

    private func delete(collection: String, id: String) async {
        await withCheckedContinuation { continuation in
            DomainDatabaseService.shared.delete(collection: collection, documentId: id) { _ in
                continuation.resume()
            }
        }
    }
}
