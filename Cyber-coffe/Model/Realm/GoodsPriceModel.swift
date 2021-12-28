//
//  GoodsPriceModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 28.12.2021.
//

import RealmSwift

class GoodsPriceModel: Object {
    @Persisted var good: String = ""
    @Persisted var price: Double = 0.0
    
}
