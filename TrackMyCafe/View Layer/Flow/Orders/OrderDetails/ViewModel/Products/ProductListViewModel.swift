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
    
    func getProducts(withIdOrder id: String, completion: @escaping () -> Void) {
        
        products.removeAll()
        
        DomainDatabaseService.shared.fetchProduct(withOrderId: id) { [weak self] products in
            guard let self = self else { return }
            
            if products.isEmpty {
                DomainDatabaseService.shared.fetchProductsPrice { productsPrice in
                    for productPrice in productsPrice {
                        let product = ProductOfOrderModel(id: "",
                                                     orderId: id,
                                                     date: Date(),
                                                     name: productPrice.name,
                                                     quantity: 0,
                                                     price: productPrice.price,
                                                     sum: 0)
                        self.products.append(product)
                    }
                    completion()
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
    }
    
    func getQuantity() -> Double {
        guard let atIndex = selectedIndexPath?.row else { return 0.0 }
        let orderQty = Double(products[atIndex].quantity)
        
        return orderQty
    }
    
    func totalSum() -> String {
        var totalSum: Double = 0.0
        for product in products {
            totalSum += product.sum
        }
        return totalSum.currency
    }
    
    func saveOrder(withOrderId id: String, date: Date) {
        for var order in products {
            order.orderId = id
            order.date = date
            DomainDatabaseService.shared.saveProduct(order: order) { [self] success in
                if success {
                    logger.notice("Order \(order.id) saved successfully")
                } else {
                    logger.error("Failed to save order \(order.id)")
                }
            }
        }
    }
    
    func updateOrder(date: Date) {
        for product in products {
            DomainDatabaseService.shared.updateProduct(model: product,
                                                        date: date,
                                                        name: product.name,
                                                        quantity: product.quantity,
                                                        price: product.price,
                                                        sum: product.sum)
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
}
