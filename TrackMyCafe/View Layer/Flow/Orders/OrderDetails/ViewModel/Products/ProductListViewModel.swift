//
//  ProductListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

class ProductListViewModel: ProductListViewModelType, Loggable {

    private var selectedIndexPath: IndexPath?
    private var products = [ProductOfOrderModel]()
    private let costingService: CostingServiceProtocol
    private let inventoryService: InventoryServiceProtocol

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
                        completion()
                    }
                }
            } else {
                self.products = products
                completion()
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
        products[tag].quantity = quantity
        products[tag].sum = Double(quantity) * products[tag].price
        products[tag].costSum = Double(quantity) * products[tag].costPrice
    }

    func getQuantity() -> Double {
        guard let atIndex = selectedIndexPath?.row else { return 0.0 }
        let orderQty = Double(products[atIndex].quantity)

        return orderQty
    }

    func getTotalAmount() -> Double {
        var totalSum: Double = 0.0
        for product in products {
            totalSum += product.sum
        }
        return totalSum
    }

    func getTotalCostAmount() -> Double {
        var totalCost: Double = 0.0
        for product in products {
            totalCost += product.costSum
        }
        return totalCost
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
                completion()
            }
        }
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

            let group = DispatchGroup()
            var hasError = false

            for var order in self.products {
                order.orderId = id
                order.date = date

                group.enter()
                DomainDatabaseService.shared.saveProduct(order: order) { id in
                    if id != nil {
                        self.logger.notice("Order \(order.id) saved successfully")
                    } else {
                        self.logger.error("Failed to save order \(order.id)")
                        hasError = true
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(!hasError)
            }
        }
    }

    func updateOrder(date: Date, completion: @escaping (Bool) -> Void) {
        guard let orderId = products.first?.orderId, !orderId.isEmpty else {
            let group = DispatchGroup()

            for product in products {
                group.enter()
                DomainDatabaseService.shared.updateProduct(
                    model: product,
                    date: date,
                    name: product.name,
                    quantity: product.quantity,
                    price: product.price,
                    sum: product.sum)
                group.leave()
            }

            group.notify(queue: .main) {
                completion(true)
            }

            return
        }

        DomainDatabaseService.shared.fetchProduct(withOrderId: orderId) { [weak self] oldProducts in
            guard let self = self else {
                completion(false)
                return
            }

            let allProductIds = Set(self.products.map { $0.productId }).union(
                oldProducts.map { $0.productId })

            let deltaItems: [OrderItemModel] = allProductIds.compactMap { productId in
                guard !productId.isEmpty else { return nil }

                let newProduct = self.products.first { $0.productId == productId }
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

            if deltaItems.isEmpty {
                completion(true)
                return
            }

            self.inventoryService.deductStock(for: deltaItems) { [weak self] result in
                guard let self = self else {
                    completion(false)
                    return
                }

                switch result {
                case .success:
                    let group = DispatchGroup()

                    for product in self.products {
                        group.enter()
                        DomainDatabaseService.shared.updateProduct(
                            model: product,
                            date: date,
                            name: product.name,
                            quantity: product.quantity,
                            price: product.price,
                            sum: product.sum)
                        group.leave()
                    }

                    group.notify(queue: .main) {
                        completion(true)
                    }
                case .failure(let error):
                    self.logger.error(
                        "Stock adjustment during order update failed: \(error.localizedDescription)"
                    )
                    completion(false)
                }
            }
        }
    }

    static func deleteOrder(withOrderId id: String, date: Date) {
        DomainDatabaseService.shared.fetchProduct(withOrderId: id) { ordersProducts in
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
        let itemsToCheck = products.filter { $0.quantity > 0 }.map {
            OrderItemModel(
                productId: $0.productId,
                quantity: $0.quantity,
                salePrice: $0.price,
                costPrice: $0.costPrice
            )
        }

        if itemsToCheck.isEmpty {
            completion([])
            return
        }

        inventoryService.validateStockAvailability(for: itemsToCheck, completion: completion)
    }

    func deductStock(completion: @escaping (Bool) -> Void) {
        let itemsToDeduct = products.filter { $0.quantity > 0 }.map {
            OrderItemModel(
                productId: $0.productId,
                quantity: $0.quantity,
                salePrice: $0.price,
                costPrice: $0.costPrice
            )
        }

        if itemsToDeduct.isEmpty {
            completion(true)
            return
        }

        inventoryService.deductStock(for: itemsToDeduct) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                self.logger.error("Stock deduction failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
}
