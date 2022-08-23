//
//  PurchaseModel.swift.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.12.2021.
//

import RealmSwift

class PurchaseModel: Object, Decodable {
    @Persisted var id: String = ""
    @Persisted var synchronized: Bool = false
    @Persisted var date: Date = Date()
    @Persisted var good: String = ""
    @Persisted var sum: Double = 0.0
    
    convenience init(documentId firId: String, firModel: FIRPurchaseModel) {
        self.init()
        self.id = firId
        self.synchronized = true
        self.date = firModel.purchaseDate
        self.good = firModel.purchaseGood
        self.sum = firModel.purchaseSum
    }
}
