//
//  SalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 14.12.2021.
//

import RealmSwift

class SalesModel: Object {
    @Persisted var saslesDate = Date()
    @Persisted var saslesSum: Double = 0.0
    @Persisted var saslesCash: Double = 0.0
    
}
