//
//  SalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 14.12.2021.
//

import Foundation
import RealmSwift

class SalesModel: Object {
    @Persisted var id: String// = ""
    @Persisted var synchronized: Bool// = false
    @Persisted var date: Date
    @Persisted var typeOfDonation: String// = "Sunday"
    @Persisted var sum: Double// = 0.0
    @Persisted var cash: Double// = 0.0
    @Persisted var card: Double// = 0.0
    
    convenience init(documentId firId: String, firModel: FIRDailySalesModel) {
        self.init()
        self.id = firId
        self.synchronized = true
        self.date = firModel.salesDate
        self.typeOfDonation = firModel.salesTypeOfDonation
        self.sum = firModel.salesSum
        self.cash = firModel.salesCash
        self.card = firModel.salesCard
    }
}
