//
//  DailySalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct DailySalesModel {
    var id: String
    var date: Date
    var incomeType: String
    var sum: Double
    var cash: Double
    var card: Double
    
    init(id: String, date: Date, incomeType: String, sum: Double, cash: Double, card: Double) {
        self.id = id
        self.date = date
        self.incomeType = incomeType
        self.sum = sum
        self.cash = cash
        self.card = card
    }
    
    init(realmModel: RealmDailySalesModel) {
        self.id = realmModel.id
        self.date = realmModel.date
        self.incomeType = realmModel.incomeType
        self.sum = realmModel.sum
        self.cash = realmModel.cash
        self.card = realmModel.card
    }
    
    init(firebaseModel: FIRDailySalesModel) {
        self.id = firebaseModel.id ?? ""
        self.date = firebaseModel.date
        self.incomeType = firebaseModel.incomeType
        self.sum = firebaseModel.sum
        self.cash = firebaseModel.cash
        self.card = firebaseModel.card
    }
}
