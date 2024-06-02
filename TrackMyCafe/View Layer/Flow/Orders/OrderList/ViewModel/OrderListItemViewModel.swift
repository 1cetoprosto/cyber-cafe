//
//  OrderListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class OrderListItemViewModel: OrderListItemViewModelType {
    
    private var model: OrderModel
    
    var productsName: String {
        return model.type
    }
    
    var ordersSum: String {
        return String(Int(model.sum))
    }
    
    var ordersLabel: String {
        return "Order"
    }
    
    var cashSum: String {
        return String(Int(model.cash))
    }
    
    var cashLabel: String {
        return "Cash"
    }
    
    init(model: OrderModel) {
        self.model = model
    }
}
