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
    private var products = [ProductOfOrderModel]()
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

    func getProducts(withIdOrder id: String, completion: @escaping () -> Void) {

        products.removeAll()

        DomainDatabaseService.shared.fetchProduct(withOrderId: id) { [weak self] products in
            guard let self = self else { return }

            if products.isEmpty {
                DomainDatabaseService.shared.fetchProductsPrice { productsPrice in
                    let group = DispatchGroup()
                    var newProducts: [ProductOfOrderModel] = []

                    for productPrice in productsPrice {
                        group.enter()
                        self.costingService.calculateProductCost(productId: productPrice.id) {
                            cost in
                            let product = ProductOfOrderModel(
                                id: "",
                                productId: productPrice.id,
                                orderId: id,
                                date: Date(),
                                name: productPrice.name,
                                quantity: 0,
                                price: productPrice.price,
                                sum: 0,
                                costPrice: cost,
                                costSum: 0)
                            // Thread-safe append
                            DispatchQueue.main.async {
                                newProducts.append(product)
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        self.products = newProducts.sorted { $0.name < $1.name }
                        self.emitChange(.fullReload)
                        completion()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.products = products
                    self.emitChange(.fullReload)
                    completion()
                }
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
        products[tag].sum = Double(quantity) * products[tag].price
        products[tag].costSum = Double(quantity) * products[tag].costPrice
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

    func addProduct(from priceModel: ProductsPriceModel, completion: @escaping () -> Void) {
        if let index = products.firstIndex(where: { $0.productId == priceModel.id }) {
            let existing = products[index]
            let newQuantity = existing.quantity + 1
            products[index].quantity = newQuantity
            products[index].sum = Double(newQuantity) * existing.price
            products[index].costSum = Double(newQuantity) * existing.costPrice
            emitChange(.productUpdated(productId: priceModel.id))
            completion()
            return
        }

        costingService.calculateProductCost(productId: priceModel.id) { [weak self] cost in
            guard let self = self else { return }

            let product = ProductOfOrderModel(
                id: "",
                productId: priceModel.id,
                orderId: "",
                date: Date(),
                name: priceModel.name,
                quantity: 1,
                price: priceModel.price,
                sum: priceModel.price,
                costPrice: cost,
                costSum: cost
            )

            DispatchQueue.main.async {
                self.products.append(product)
                self.products.sort { $0.name < $1.name }
                self.emitChange(.fullReload)
                completion()
            }
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

    func saveOrder(withOrderId id: String, date: Date, completion: @escaping (Bool) -> Void) {
        deductStock { [weak self] success in
            guard let self = self else { return }

            if !success {
                self.logger.error("Stock deduction failed")
            }

            self.persistProducts(orderId: id, date: date, completion: completion)
        }
    }

    func updateOrder(orderId: String, date: Date, completion: @escaping (Bool) -> Void) {
        DomainDatabaseService.shared.fetchProduct(withOrderId: orderId) { [weak self] oldProducts in
            guard let self = self else {
                completion(false)
                return
            }

            self.prepareProducts(for: orderId, date: date)

            let deltaItems = self.computeDeltaItems(
                currentProducts: self.products,
                oldProducts: oldProducts
            )

            if deltaItems.isEmpty {
                self.persistProducts(
                    orderId: orderId,
                    date: date,
                    completion: completion
                )
                return
            }

            let revertItems: [OrderItemModel] =
                oldProducts
                .filter { $0.quantity > 0 }
                .map(\.orderItemSnapshot)
            let applyItems: [OrderItemModel] = self.products
                .filter { $0.quantity > 0 }
                .map(\.orderItemSnapshot)

            self.applyInventoryUpdates(
                revertItems: revertItems,
                applyItems: applyItems,
                orderId: orderId,
                date: date,
                completion: completion
            )
        }
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
        currentProducts: [ProductOfOrderModel],
        oldProducts: [ProductOfOrderModel]
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

            let salePrice = newProduct?.price ?? oldProduct?.price ?? 0.0
            let costPrice = newProduct?.costPrice ?? oldProduct?.costPrice ?? 0.0

            return OrderItemModel(
                productId: productId,
                quantity: deltaQty,
                salePrice: salePrice,
                costPrice: costPrice
            )
        }
    }

    private func persistProducts(
        orderId: String,
        date: Date,
        completion: @escaping (Bool) -> Void
    ) {
        let group = DispatchGroup()
        var hasError = false

        for i in products.indices {
            var product = products[i]
            product.orderId = orderId
            product.date = date

            group.enter()
            let productIndex = i
            let snapshot = product
            DomainDatabaseService.shared.saveProduct(order: snapshot) { [weak self] newId in
                defer { group.leave() }
                guard let self = self else { return }
                if let newId {
                    DispatchQueue.main.async {
                        var updated = snapshot
                        updated.id = newId
                        if self.products.indices.contains(productIndex) {
                            self.products[productIndex] = updated
                        }
                    }
                } else {
                    hasError = true
                }
            }
        }

        group.notify(queue: .main) {
            completion(!hasError)
        }
    }

    private func applyInventoryUpdates(
        revertItems: [OrderItemModel],
        applyItems: [OrderItemModel],
        orderId: String,
        date: Date,
        completion: @escaping (Bool) -> Void
    ) {
        let finishSaving: () -> Void = { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            self.persistProducts(
                orderId: orderId,
                date: date,
                completion: completion
            )
        }

        let outerGroup = DispatchGroup()
        var inventoryError = false

        if !revertItems.isEmpty {
            outerGroup.enter()
            inventoryService.restoreStock(
                for: revertItems,
                trackingEnabled: inventoryTrackingMode
            ) { [weak self] result in
                if case .failure(let error) = result {
                    self?.logger.error(
                        "Stock revert failed on order update: \(error.localizedDescription)"
                    )
                    inventoryError = true
                }
                outerGroup.leave()
            }
        }

        outerGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if inventoryError {
                completion(false)
                return
            }

            let applyGroup = DispatchGroup()

            if !applyItems.isEmpty {
                applyGroup.enter()
                self.inventoryService.deductStock(
                    for: applyItems,
                    trackingEnabled: self.inventoryTrackingMode
                ) { [weak self] result in
                    if case .failure(let error) = result {
                        self?.logger.error(
                            "Stock apply failed on order update: \(error.localizedDescription)"
                        )
                        inventoryError = true
                    }
                    applyGroup.leave()
                }
            }

            applyGroup.notify(queue: .main) {
                if inventoryError {
                    completion(false)
                    return
                }
                finishSaving()
            }
        }
    }

    static func deleteOrder(
        withOrderId id: String,
        date: Date,
        trackingEnabled: Bool,
        inventoryService: InventoryServiceProtocol = InventoryService.shared
    ) {
        DomainDatabaseService.shared.fetchProduct(withOrderId: id) { ordersProducts in
            let orderItems: [OrderItemModel] =
                ordersProducts
                .filter { $0.quantity > 0 }
                .map(\.orderItemSnapshot)

            if !orderItems.isEmpty {
                inventoryService.restoreStock(
                    for: orderItems,
                    trackingEnabled: trackingEnabled
                ) { result in
                    switch result {
                    case .success:
                        logger.notice("Restored stock for deleted order \(id) successfully")
                    case .failure(let error):
                        logger.error(
                            "Failed to restore stock for deleted order \(id): \(error.localizedDescription)"
                        )
                    }
                }
            }

            for product in ordersProducts {
                DomainDatabaseService.shared.deleteProduct(order: product) { success in
                    if success {
                        logger.notice("Delete order \(product.id) successfully")
                    } else {
                        logger.error("Failed to delete order \(product.id)")
                    }
                }
            }
        }
    }

    // MARK: - Inventory Integration

    func validateStock(completion: @escaping ([StockWarning]) -> Void) {
        validateStock(
            trackingEnabled: inventoryTrackingMode,
            completion: completion
        )
    }

    func validateStock(
        trackingEnabled: Bool,
        completion: @escaping ([StockWarning]) -> Void
    ) {
        let itemsToCheck = activeOrderItems()

        if itemsToCheck.isEmpty {
            completion([])
            return
        }

        inventoryService.validateStockAvailability(
            for: itemsToCheck,
            trackingEnabled: trackingEnabled,
            completion: completion
        )
    }

    func deductStock(completion: @escaping (Bool) -> Void) {
        deductStock(
            trackingEnabled: inventoryTrackingMode,
            completion: completion
        )
    }

    func deductStock(
        trackingEnabled: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        let itemsToDeduct = activeOrderItems()

        if itemsToDeduct.isEmpty {
            completion(true)
            return
        }

        inventoryService.deductStock(
            for: itemsToDeduct,
            trackingEnabled: trackingEnabled
        ) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                self.logger.error("Stock deduction failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    private func activeOrderItems() -> [OrderItemModel] {
        products
            .filter { $0.quantity > 0 }
            .map(\.orderItemSnapshot)
    }

    private func orderMetrics() -> (totalSale: Double, totalCost: Double) {
        costingService.calculateOrderMetrics(items: activeOrderItems())
    }
}
