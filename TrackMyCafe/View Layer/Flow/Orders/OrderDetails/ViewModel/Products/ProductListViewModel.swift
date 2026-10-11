//
//  ProductListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

enum ProductListChange {
    case fullReload
    case productUpdated(productId: String)
}

class ProductListViewModel: ProductListViewModelType, Loggable {

    private var selectedIndexPath: IndexPath?
    private var products = [OrderItemModel]()
    private let costingService: CostingServiceProtocol
    private let inventoryService: InventoryServiceProtocol
    private var inventoryTrackingModeOverride: Bool?

    var inventoryTrackingMode: Bool {
        get { inventoryTrackingModeOverride ?? SettingsManager.shared.loadTrackIngredients() }
        set { inventoryTrackingModeOverride = newValue }
    }

    var onChange: ((ProductListChange) -> Void)?

    private func emitChange(_ change: ProductListChange) {
        onChange?(change)
        var userInfo: [AnyHashable: Any] = [:]
        switch change {
        case .fullReload:
            userInfo["fullReload"] = true
        case .productUpdated(let productId):
            userInfo["productId"] = productId
        }
        NotificationCenter.default.post(
            name: .productListDidChange,
            object: self,
            userInfo: userInfo
        )
    }

    init(
        costingService: CostingServiceProtocol = CostingService.shared,
        inventoryService: InventoryServiceProtocol = InventoryService.shared
    ) {
        self.costingService = costingService
        self.inventoryService = inventoryService
    }

    func getProducts(withIdOrder id: String) async {
        products.removeAll()

        let fetchedProducts = await DomainDatabaseService.shared.fetchProduct(withOrderId: id)

        if fetchedProducts.isEmpty {
            let productsPrice = await DomainDatabaseService.shared.fetchProductsPrice()
            var newProducts: [OrderItemModel] = []

            for productPrice in productsPrice {
                let cost = await costingService.calculateProductCost(productId: productPrice.id)
                let product = OrderItemModel(
                    id: "",
                    productId: productPrice.id,
                    name: productPrice.name,
                    orderId: id,
                    date: Date(),
                    quantity: 0,
                    salePrice: productPrice.price,
                    costPrice: cost)
                newProducts.append(product)
            }

            let sortedProducts = newProducts.sorted { $0.name < $1.name }
            await MainActor.run {
                self.products = sortedProducts
                self.emitChange(.fullReload)
            }
        } else {
            await MainActor.run {
                self.products = fetchedProducts
                self.emitChange(.fullReload)
            }
        }
    }

    func numberOfRowInSection(for section: Int) -> Int {
        return products.count
    }

    func cellViewModel(for indexPath: IndexPath) -> ProductListItemViewModelType? {
        let product = products[indexPath.row]
        return ProductListItemViewModel(product: product, for: indexPath.row)
    }

    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }

    func setQuantity(tag: Int, quantity: Int) {
        guard products.indices.contains(tag) else { return }
        let wasActive = products[tag].quantity > 0
        products[tag].quantity = quantity
        let isActive = quantity > 0
        if wasActive != isActive {
            emitChange(.fullReload)
        } else {
            emitChange(.productUpdated(productId: products[tag].productId))
        }
    }

    func getQuantity() -> Double {
        guard let atIndex = selectedIndexPath?.row else { return 0.0 }
        let orderQty = Double(products[atIndex].quantity)

        return orderQty
    }

    func getTotalAmount() -> Double {
        orderMetrics().totalSale
    }

    func getTotalCostAmount() -> Double {
        orderMetrics().totalCost
    }

    func clearProducts() {
        products.removeAll()
    }

    func addProduct(from priceModel: ProductsPriceModel) async {
        if let index = products.firstIndex(where: { $0.productId == priceModel.id }) {
            let existing = products[index]
            let newQuantity = existing.quantity + 1
            products[index].quantity = newQuantity
            emitChange(.productUpdated(productId: priceModel.id))
            return
        }

        let cost = await costingService.calculateProductCost(productId: priceModel.id)

        let product = OrderItemModel(
            id: "",
            productId: priceModel.id,
            name: priceModel.name,
            orderId: "",
            date: Date(),
            quantity: 1,
            salePrice: priceModel.price,
            costPrice: cost
        )

        await MainActor.run {
            self.products.append(product)
            self.products.sort { $0.name < $1.name }
            self.emitChange(.fullReload)
        }
    }

    func activeProductIds() -> [String] {
        products.filter { $0.quantity > 0 }.map(\.productId)
    }

    func index(forProductId productId: String) -> Int? {
        products.firstIndex(where: { $0.productId == productId })
    }

    func quantity(forProductId productId: String) -> Int? {
        guard let index = index(forProductId: productId) else { return nil }
        return products[index].quantity
    }

    func totalSum() -> String {
        return getTotalAmount().currency
    }

    func saveOrder(withOrderId id: String, date: Date) async -> Bool {
        let success = await deductStock()
        if !success {
            logger.error("Stock deduction failed")
        }

        return await persistProductsSuccess(orderId: id, date: date)
    }

    func updateOrder(orderId: String, date: Date) async -> Bool {
        let oldProducts = await DomainDatabaseService.shared.fetchProduct(withOrderId: orderId)

        prepareProducts(for: orderId, date: date)

        let deltaItems = computeDeltaItems(
            currentProducts: products,
            oldProducts: oldProducts
        )

        if deltaItems.isEmpty {
            return await persistProductsSuccess(orderId: orderId, date: date)
        }

        let revertItems: [OrderItemModel] =
            oldProducts
            .filter { $0.quantity > 0 }
        let applyItems: [OrderItemModel] =
            products
            .filter { $0.quantity > 0 }

        return await applyInventoryUpdates(
            revertItems: revertItems,
            applyItems: applyItems,
            orderId: orderId,
            date: date
        )
    }

    // MARK: - Private Helpers

    private func prepareProducts(for orderId: String, date: Date) {
        for i in products.indices {
            if products[i].orderId.isEmpty {
                products[i].orderId = orderId
            }
            products[i].date = date
        }
    }

    private func computeDeltaItems(
        currentProducts: [OrderItemModel],
        oldProducts: [OrderItemModel]
    ) -> [OrderItemModel] {
        let allProductIds = Set(currentProducts.map { $0.productId }).union(
            oldProducts.map { $0.productId })

        return allProductIds.compactMap { productId in
            guard !productId.isEmpty else { return nil }

            let newProduct = currentProducts.first { $0.productId == productId }
            let oldProduct = oldProducts.first { $0.productId == productId }

            let newQty = newProduct?.quantity ?? 0
            let oldQty = oldProduct?.quantity ?? 0
            let deltaQty = newQty - oldQty

            guard deltaQty != 0 else { return nil }

            let salePrice = newProduct?.salePrice ?? oldProduct?.salePrice ?? 0.0
            let costPrice = newProduct?.costPrice ?? oldProduct?.costPrice ?? 0.0

            return OrderItemModel(
                productId: productId,
                quantity: deltaQty,
                salePrice: salePrice,
                costPrice: costPrice
            )
        }
    }

    @discardableResult
    private func persistProductsSuccess(orderId: String, date: Date) async -> Bool {
        var hasError = false

        for i in products.indices {
            var product = products[i]
            product.orderId = orderId
            product.date = date

            let newId = await DomainDatabaseService.shared.saveProduct(order: product)
            if let newId = newId {
                let productCopy = product
                await MainActor.run {
                    var updated = productCopy
                    updated.id = newId
                    if self.products.indices.contains(i) {
                        self.products[i] = updated
                    }
                }
            } else {
                hasError = true
            }
        }

        return !hasError
    }

    private func applyInventoryUpdates(
        revertItems: [OrderItemModel],
        applyItems: [OrderItemModel],
        orderId: String,
        date: Date
    ) async -> Bool {
        var inventoryError = false

        if !revertItems.isEmpty {
            do {
                try await inventoryService.restoreStock(
                    for: revertItems,
                    trackingEnabled: inventoryTrackingMode
                )
            } catch {
                logger.error(
                    "Stock revert failed on order update: \(error.localizedDescription)"
                )
                inventoryError = true
            }
        }

        if inventoryError {
            return false
        }

        if !applyItems.isEmpty {
            do {
                try await inventoryService.deductStock(
                    for: applyItems,
                    trackingEnabled: inventoryTrackingMode
                )
            } catch {
                logger.error(
                    "Stock apply failed on order update: \(error.localizedDescription)"
                )
                inventoryError = true
            }
        }

        if inventoryError {
            return false
        }

        return await persistProductsSuccess(orderId: orderId, date: date)
    }

    static func deleteOrder(
        withOrderId id: String,
        date: Date,
        trackingEnabled: Bool,
        inventoryService: InventoryServiceProtocol = InventoryService.shared
    ) {
        Task {
            let ordersProducts = await DomainDatabaseService.shared.fetchProduct(withOrderId: id)
            let orderItems: [OrderItemModel] =
                ordersProducts
                .filter { $0.quantity > 0 }

            if !orderItems.isEmpty {
                do {
                    try await inventoryService.restoreStock(
                        for: orderItems,
                        trackingEnabled: trackingEnabled
                    )
                    logger.notice("Restored stock for deleted order \(id) successfully")
                } catch {
                    logger.error(
                        "Failed to restore stock for deleted order \(id): \(error.localizedDescription)"
                    )
                }
            }

            for product in ordersProducts {
                let success = await DomainDatabaseService.shared.deleteProduct(order: product)
                if success {
                    logger.notice("Delete order \(product.id) successfully")
                } else {
                    logger.error("Failed to delete order \(product.id)")
                }
            }
        }
    }

    // MARK: - Inventory Integration

    func validateStock() async -> [StockWarning] {
        await validateStock(trackingEnabled: inventoryTrackingMode)
    }

    private func validateStock(trackingEnabled: Bool) async -> [StockWarning] {
        let itemsToCheck = activeOrderItems()

        if itemsToCheck.isEmpty {
            return []
        }

        return await inventoryService.validateStockAvailability(
            for: itemsToCheck,
            trackingEnabled: trackingEnabled
        )
    }

    func deductStock() async -> Bool {
        await deductStock(trackingEnabled: inventoryTrackingMode)
    }

    private func deductStock(trackingEnabled: Bool) async -> Bool {
        let itemsToDeduct = activeOrderItems()

        if itemsToDeduct.isEmpty {
            return true
        }

        do {
            try await inventoryService.deductStock(
                for: itemsToDeduct,
                trackingEnabled: trackingEnabled
            )
            return true
        } catch {
            logger.error("Stock deduction failed: \(error.localizedDescription)")
            return false
        }
    }

    private func activeOrderItems() -> [OrderItemModel] {
        products
            .filter { $0.quantity > 0 }
    }

    private func orderMetrics() -> (totalSale: Double, totalCost: Double) {
        costingService.calculateOrderMetrics(items: activeOrderItems())
    }
}
