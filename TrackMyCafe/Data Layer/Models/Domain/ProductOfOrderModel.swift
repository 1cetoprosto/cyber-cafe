//
//  ProductModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct ProductOfOrderModel {
    var id: String
    var productId: String
    var orderId: String
    var date: Date
    var name: String
    var quantity: Int
    var price: Double
    var sum: Double
    var costPrice: Double
    var costSum: Double
    
    init(id: String, productId: String = "", orderId: String, date: Date, name: String, quantity: Int, price: Double, sum: Double, costPrice: Double = 0.0, costSum: Double = 0.0) {
        self.id = id
        self.productId = productId
        self.orderId = orderId
        self.date = date
        self.name = name
        self.quantity = quantity
        self.price = price
        self.sum = sum
        self.costPrice = costPrice
        self.costSum = costSum
    }
    
    init(realmModel: RealmProductModel) {
        self.id = realmModel.id
        self.productId = realmModel.productId
        self.orderId = realmModel.orderId
        self.date = realmModel.date
        self.name = realmModel.name
        self.quantity = realmModel.quantity
        self.price = realmModel.price
        self.sum = realmModel.sum
        self.costPrice = realmModel.costPrice
        self.costSum = realmModel.costSum
    }
    
    init(firebaseModel: FIRProductModel) {
        self.id = firebaseModel.id ?? ""
        self.productId = firebaseModel.productId ?? ""
        self.orderId = firebaseModel.orderId ?? ""
        self.date = firebaseModel.date
        self.name = firebaseModel.name
        self.quantity = firebaseModel.quantity
        self.price = firebaseModel.price
        self.sum = firebaseModel.amount
        self.costPrice = firebaseModel.costPrice
        self.costSum = firebaseModel.costSum
    }
}
