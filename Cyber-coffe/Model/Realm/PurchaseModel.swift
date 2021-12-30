//
//  PurchaseModel.swift.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.12.2021.
//

import RealmSwift

class PurchaseModel: Object {
    @Persisted var purchaseDate = Date()
    @Persisted var purchaseGood: String = ""
    @Persisted var purchaseSum: Double = 0.0
}
