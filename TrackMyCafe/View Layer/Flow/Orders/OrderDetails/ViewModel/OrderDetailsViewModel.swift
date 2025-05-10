//
//  OrderDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class OrderDetailsViewModel: OrderDetailsViewModelType, Loggable {
    
    private var order: OrderModel
    private var types: [TypeModel]  = []
    private var selectedRow: Int?
    
    var id: String { return order.id }
    var date: Date { return order.date }
    var cashLabel: String { return "Cash:" }
    var cardLabel: String { return "Card:" }
    var cashTextfield: String { return "Money2:" }
    var cardTextfield: String { return "Money3:" }
    var orderLabel: String { return "Money1:" }
    var cash: Double { return order.cash }
    var card: Double { return order.card }
    var sum: Double { return order.sum }
    var type: String { return order.type }
    var isNewModel: Bool
    
    init(model: OrderModel, isNewModel: Bool = false) {
        self.order = model
        self.isNewModel = isNewModel
        fetchTypes()
    }
    
    func isExist(id: String, completion: @escaping (Bool) -> Void) {
        DomainDatabaseService.shared.fetchOrders(forId: id) { order in
            completion(order != nil)
        }
    }
    
    func saveOrders(id: String, date: Date, type: String?, cash: String?, card: String?, sum: String?, completion: @escaping () -> Void) {
        let order = OrderModel(
            id: id,
            date: date,
            type: type ?? "",
            sum: sum?.double ?? 0.0,
            cash: cash?.double ?? 0.0,
            card: card?.double ?? 0.0
        )
        
        DomainDatabaseService.shared.saveOrder(order: order) { [self] documentId in
            guard let documentId = documentId else {
                logger.error("Failed to save order")
                return
            }
            self.order.id = documentId
            completion()
            logger.notice("Order \(documentId) saved successfully")
        }
    }
    
    func updateOrders(id: String, date: Date, type: String?, cash: String?, card: String?, sum: String?, completion: @escaping () -> Void) {
        
        DomainDatabaseService.shared.fetchOrders(forId: id) { order in
            guard let order = order else { return }
                DomainDatabaseService.shared.updateOrders(model: order,
                                                         date: date,
                                                         type: type ?? "",
                                                         total: sum?.double ?? 0.0,
                                                         cashAmount: cash?.double ?? 0.0,
                                                         cardAmount: card?.double ?? 0.0)
        completion()
        }
    }
    
    func numberOfRowsInComponent(component: Int) -> Int {
        //guard let types = self.types else { return 0 }
        return types.count
    }
    
    func titleForRow(row: Int, component: Int) -> String? {
        //guard let types = self.types else { return nil }
        return types[row].name
    }
    
    func selectRow(atRow row: Int) {
        self.selectedRow = row
    }
    
    func fetchTypes() {
        DomainDatabaseService.shared.fetchTypes { [weak self] types in
            self?.types = types
        }
    }
    
    // Check if required data exists
    func verifyRequiredData(completion: @escaping (Bool) -> Void) {
        DomainDatabaseService.shared.fetchTypes { [weak self] types in
            guard let self = self else { return }
            self.types = types
            DomainDatabaseService.shared.fetchProductsPrice { productPrices in
                completion(!types.isEmpty && !productPrices.isEmpty)
            }
        }
    }
}
