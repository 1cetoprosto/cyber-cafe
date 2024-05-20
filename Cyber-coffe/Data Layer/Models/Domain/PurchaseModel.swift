//
//  PurchaseModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct PurchaseModel {
    var id: String
    var date: Date
    var name: String
    var sum: Double
    
    init(id: String, date: Date, name: String, sum: Double) {
        self.id = id
        self.date = date
        self.name = name
        self.sum = sum
    }
    
    init(realmModel: RealmPurchaseModel) {
        self.id = realmModel.id
        self.date = realmModel.date
        self.name = realmModel.name
        self.sum = realmModel.sum
    }
    
    init(firebaseModel: FIRPurchaseModel) {
        self.id = firebaseModel.id ?? ""
        self.date = firebaseModel.date
        self.name = firebaseModel.name
        self.sum = firebaseModel.sum
    }
}

