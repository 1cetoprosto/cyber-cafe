//
//  SalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import RealmSwift

class SaleGoodModel: Object {
    @Persisted var id: String = ""
    @Persisted var synchronized: Bool = false
    @Persisted var date = Date()
    @Persisted var saleGood: String = ""
    @Persisted var saleQty: Int = 0
    @Persisted var salePrice: Double = 0.0
    @Persisted var saleSum: Double = 0.0
}
