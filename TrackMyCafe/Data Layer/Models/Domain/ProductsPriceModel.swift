//
//  ProductsPriceModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct ProductsPriceModel {
    var id: String
    var name: String
    var price: Double
    
    init(id: String, name: String, price: Double) {
        self.id = id
        self.name = name
        self.price = price
    }
    
    init(realmModel: RealmProductsPriceModel) {
        self.id = realmModel.id
        self.name = realmModel.name
        self.price = realmModel.price
    }
    
    init(firebaseModel: FIRProductsPriceModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
        self.price = firebaseModel.price
    }
}

