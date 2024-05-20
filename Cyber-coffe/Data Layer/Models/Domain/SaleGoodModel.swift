//
//  SaleGoodModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct SaleGoodModel {
    var id: String
    var date: Date
    var name: String
    var quantity: Int
    var price: Double
    var sum: Double
    
    init(id: String, date: Date, name: String, quantity: Int, price: Double, sum: Double) {
        self.id = id
        self.date = date
        self.name = name
        self.quantity = quantity
        self.price = price
        self.sum = sum
    }
    
    init(realmModel: RealmSaleGoodModel) {
        self.id = realmModel.id
        self.date = realmModel.date
        self.name = realmModel.name
        self.quantity = realmModel.quantity
        self.price = realmModel.price
        self.sum = realmModel.sum
    }
    
    init(firebaseModel: FIRSaleGoodModel) {
        self.id = firebaseModel.id ?? ""
        self.date = firebaseModel.date
        self.name = firebaseModel.name
        self.quantity = firebaseModel.quantity
        self.price = firebaseModel.price
        self.sum = firebaseModel.amount
    }
}
