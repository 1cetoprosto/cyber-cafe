//
//  OrdersModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 14.12.2021.
//

import Foundation
import RealmSwift

class RealmOrderModel: Object, DateContainable {
    @Persisted var id: String// = ""
    @Persisted var date: Date = Date()
    @Persisted var type: String// = "Sunday"
    @Persisted var sum: Double// = 0.0
    @Persisted var cash: Double// = 0.0
    @Persisted var card: Double// = 0.0
    
    convenience init(dataModel: OrderModel) {
        self.init()
        self.id = dataModel.id
        self.date = dataModel.date
        self.type = dataModel.type
        self.sum = dataModel.sum
        self.cash = dataModel.cash
        self.card = dataModel.card
    }
}
