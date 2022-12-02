//
//  GoodsPriceModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 28.12.2021.
//

import RealmSwift

class GoodsPriceModel: Object {
    @Persisted var id: String = ""
    @Persisted var synchronized: Bool = false
    @Persisted var good: String = ""
    @Persisted var price: Double = 0.0
    
    convenience init(documentId firId: String, firModel: FIRGoodsPriceModel) {
        self.init()
        self.id = firId
        self.synchronized = true
        self.good = firModel.good
        self.price = firModel.price
    }
}
