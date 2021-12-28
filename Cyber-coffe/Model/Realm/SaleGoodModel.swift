//
//  SalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import RealmSwift

class SaleGoodModel: Object {
    @Persisted var saleDate = Date()
    @Persisted var saleGood: String = ""
    @Persisted var saleQty: Int = 0
    @Persisted var saleSum: Double = 0.0
}
