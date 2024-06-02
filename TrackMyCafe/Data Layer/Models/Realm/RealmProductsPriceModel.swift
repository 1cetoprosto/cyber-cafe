//
//  RealmProductsPriceModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 28.12.2021.
//

import RealmSwift

class RealmProductsPriceModel: Object {
    @Persisted var id: String = ""
    @Persisted var name: String = ""
    @Persisted var price: Double = 0.0
    
    convenience init(dataModel: ProductsPriceModel) {
        self.init()
        self.id = dataModel.id
        self.name = dataModel.name
        self.price = dataModel.price
    }
}
