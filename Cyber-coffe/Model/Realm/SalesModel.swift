//
//  SalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 14.12.2021.
//

import RealmSwift

class SalesModel: Object {
    @Persisted var salesDate = Date()
    @Persisted var salesTypeOfDonation: String = "Sunday service"
    @Persisted var salesSum: Double = 0.0
    @Persisted var salesCash: Double = 0.0
}
