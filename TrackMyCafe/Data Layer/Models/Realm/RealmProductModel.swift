//
//  RealmProductModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import Foundation
import RealmSwift

class RealmProductModel: Object, DateContainable {
    @Persisted var id: String = ""
    @Persisted var orderId: String = ""
    @Persisted var date = Date()
    @Persisted var name: String = ""
    @Persisted var quantity: Int = 0
    @Persisted var price: Double = 0.0
    @Persisted var sum: Double = 0.0
    
    convenience init(dataModel: ProductOfOrderModel) {
        self.init()
        self.id = dataModel.id
        self.orderId = dataModel.orderId
        self.date = dataModel.date
        self.name = dataModel.name
        self.quantity = dataModel.quantity
        self.price = dataModel.price
        self.sum = dataModel.sum
    }
}
