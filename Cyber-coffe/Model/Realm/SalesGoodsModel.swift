//
//  SalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import RealmSwift

class SalesGoodsModel: Object {
    @Persisted var saslesDate = Date()
    @Persisted var saslesGood: String = ""
    @Persisted var saslesQty: Int = 0
    @Persisted var saslesSum: Double = 0.0
}
