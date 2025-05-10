//
//  ProductModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct ProductOfOrderModel {
    var id: String
    var orderId: String
    var date: Date
    var name: String
    var quantity: Int
    var price: Double
    var sum: Double
    
    init(id: String, orderId: String, date: Date, name: String, quantity: Int, price: Double, sum: Double) {
        self.id = id
        self.orderId = orderId
        self.date = date
        self.name = name
        self.quantity = quantity
        self.price = price
        self.sum = sum
    }
    
    init(realmModel: RealmProductModel) {
        self.id = realmModel.id
        self.orderId = realmModel.orderId
        self.date = realmModel.date
        self.name = realmModel.name
        self.quantity = realmModel.quantity
        self.price = realmModel.price
        self.sum = realmModel.sum
    }
    
    init(firebaseModel: FIRProductModel) {
        self.id = firebaseModel.id ?? ""
        self.orderId = firebaseModel.orderId ?? ""
        self.date = firebaseModel.date
        self.name = firebaseModel.name
        self.quantity = firebaseModel.quantity
        self.price = firebaseModel.price
        self.sum = firebaseModel.amount
    }
}
