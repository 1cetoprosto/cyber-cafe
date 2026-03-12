//
//  OrdersModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 14.12.2021.
//

import Foundation
import RealmSwift

class RealmOrderModel: Object, DateContainable {
    @Persisted var id: String
    @Persisted var date: Date = Date()
    @Persisted var type: String
    @Persisted var sum: Double
    @Persisted var cash: Double
    @Persisted var card: Double
    @Persisted var totalCost: Double
    @Persisted var note: String?
    
    convenience init(dataModel: OrderModel) {
        self.init()
        self.id = dataModel.id
        self.date = dataModel.date
        self.type = dataModel.type
        self.sum = dataModel.sum
        self.cash = dataModel.cash
        self.card = dataModel.card
        self.totalCost = dataModel.totalCost
        self.note = dataModel.note
    }
}
