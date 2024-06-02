//
//  OrderModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct OrderModel {
    var id: String
    var date: Date
    var type: String
    var sum: Double
    var cash: Double
    var card: Double
    
    init(id: String, date: Date, type: String, sum: Double, cash: Double, card: Double) {
        self.id = id
        self.date = date
        self.type = type
        self.sum = sum
        self.cash = cash
        self.card = card
    }
    
    init(realmModel: RealmOrderModel) {
        self.id = realmModel.id
        self.date = realmModel.date
        self.type = realmModel.type
        self.sum = realmModel.sum
        self.cash = realmModel.cash
        self.card = realmModel.card
    }
    
    init(firebaseModel: FIROrderModel) {
        self.id = firebaseModel.id ?? ""
        self.date = firebaseModel.date
        self.type = firebaseModel.type
        self.sum = firebaseModel.sum
        self.cash = firebaseModel.cash
        self.card = firebaseModel.card
    }
}
