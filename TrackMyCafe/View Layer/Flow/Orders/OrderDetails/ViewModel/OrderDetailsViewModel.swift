//
//  OrderDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class OrderDetailsViewModel: OrderDetailsViewModelType, Loggable {
    
    // MARK: - Properties
    private var order: OrderModel
    private var types: [TypeModel] = []
    private var selectedRow: Int?
    
    let productsViewModel: ProductListViewModel
    
    var id: String { return order.id }
    var date: Date { return order.date }
    var cashLabel: String { return R.string.global.receivedInCash() }
    var cardLabel: String { return R.string.global.receivedByCard() }
    var cashTextfield: String { return R.string.global.money2() }
    var cardTextfield: String { return R.string.global.money3() }
    var orderLabel: String { return R.string.global.totalTitle() }
    var cash: Double { return order.cash }
    var card: Double { return order.card }
    var sum: Double { return order.sum }
    var type: String { return order.type }
    var isNewModel: Bool
    
    // MARK: - Init
    init(model: OrderModel, isNewModel: Bool = false) {
        self.order = model
        self.isNewModel = isNewModel
        self.productsViewModel = ProductListViewModel()
        
        fetchTypes()
    }
    
    // MARK: - Data Loading
    func loadProducts(completion: @escaping () -> Void) {
        // If new model, pass empty string to load template products, else pass real ID
        let orderId = isNewModel ? "" : order.id
        productsViewModel.getProducts(withIdOrder: orderId, completion: completion)
    }
    
    // MARK: - Saving Logic
    func save(
        date: Date,
        type: String?,
        cash: String?,
        card: String?,
        ignoreStockWarning: Bool,
        completion: @escaping (Result<Void, OrderSaveError>) -> Void
    ) {
        let type = type ?? ""
        let cashValue = cash?.double ?? 0.0
        let cardValue = card?.double ?? 0.0
        
        if ignoreStockWarning {
            performSave(date: date, type: type, cash: cashValue, card: cardValue, completion: completion)
        } else {
            productsViewModel.validateStock { [weak self] warnings in
                guard let self = self else { return }
                
                if !warnings.isEmpty {
                    completion(.failure(.stockValidationFailed(warnings)))
                    return
                }
                
                self.performSave(date: date, type: type, cash: cashValue, card: cardValue, completion: completion)
            }
        }
    }
    
    private func performSave(date: Date, type: String, cash: Double, card: Double, completion: @escaping (Result<Void, OrderSaveError>) -> Void) {
        // 1. Save/Update Order (Parent)
        if self.isNewModel {
            self.createOrder(date: date, type: type, cash: cash, card: card) { success in
                if success {
                    // 2. Save Products (Children)
                    self.productsViewModel.saveOrder(withOrderId: self.order.id, date: date) { productsSaved in
                        if productsSaved {
                            completion(.success(()))
                        } else {
                            completion(.failure(.saveFailed))
                        }
                    }
                } else {
                    completion(.failure(.saveFailed))
                }
            }
        } else {
            self.updateOrder(date: date, type: type, cash: cash, card: card) { success in
                if success {
                    // 2. Update Products (Children)
                    self.productsViewModel.updateOrder(date: date) { productsSaved in
                        if productsSaved {
                            completion(.success(()))
                        } else {
                            completion(.failure(.saveFailed))
                        }
                    }
                } else {
                    completion(.failure(.saveFailed))
                }
            }
        }
    }
    
    private func createOrder(date: Date, type: String, cash: Double, card: Double, completion: @escaping (Bool) -> Void) {
        let sumString = productsViewModel.totalSum()
        let sum = sumString.double ?? 0.0
        
        let newOrder = OrderModel(
            id: id,
            date: date,
            type: type,
            sum: sum,
            cash: cash,
            card: card
        )
        
        DomainDatabaseService.shared.saveOrder(order: newOrder) { [weak self] documentId in
            guard let documentId = documentId else {
                completion(false)
                return
            }
            self?.order.id = documentId
            self?.isNewModel = false
            completion(true)
        }
    }
    
    private func updateOrder(date: Date, type: String, cash: Double, card: Double, completion: @escaping (Bool) -> Void) {
        let sumString = productsViewModel.totalSum()
        let sum = sumString.double ?? 0.0
        
        DomainDatabaseService.shared.fetchOrders(forId: id) { [weak self] fetchedOrder in
            guard let self = self, let fetchedOrder = fetchedOrder else {
                completion(false)
                return
            }
            
            DomainDatabaseService.shared.updateOrders(
                model: fetchedOrder,
                date: date,
                type: type,
                total: sum,
                cashAmount: cash,
                cardAmount: card
            )
            completion(true)
        }
    }
    
    // MARK: - Picker Data Source
    func numberOfRowsInComponent(component: Int) -> Int {
        return types.count
    }
    
    func titleForRow(row: Int, component: Int) -> String? {
        return types[row].name
    }
    
    func selectRow(atRow row: Int) {
        self.selectedRow = row
    }
    
    func getSelectedType() -> String? {
        guard let row = selectedRow, row < types.count else { return nil }
        return types[row].name
    }
    
    // MARK: - Helpers
    func fetchTypes() {
        DomainDatabaseService.shared.fetchTypes { [weak self] types in
            self?.types = types
            if let index = types.firstIndex(where: { $0.name == self?.order.type }) {
                self?.selectedRow = index
            }
        }
    }
    
    func verifyRequiredData(completion: @escaping (Bool) -> Void) {
        DomainDatabaseService.shared.fetchTypes { [weak self] types in
            guard let self = self else { return }
            self.types = types
            DomainDatabaseService.shared.fetchProductsPrice { productPrices in
                completion(!types.isEmpty && !productPrices.isEmpty)
            }
        }
    }
    
    func deleteOrder(completion: @escaping () -> Void) {
        ProductListViewModel.deleteOrder(withOrderId: id, date: date)
        DomainDatabaseService.shared.deleteOrder(order: order) { success in
            if success {
                self.logger.notice("Order deleted")
            }
            completion()
        }
    }
}
