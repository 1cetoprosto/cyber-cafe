//
//  SalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 14.12.2021.
//

import Foundation
import RealmSwift

class RealmDailySalesModel: Object {
    @Persisted var id: String// = ""
    @Persisted var date: Date
    @Persisted var incomeType: String// = "Sunday"
    @Persisted var sum: Double// = 0.0
    @Persisted var cash: Double// = 0.0
    @Persisted var card: Double// = 0.0
    
    convenience init(dataModel: DailySalesModel) {
        self.init()
        self.id = dataModel.id
        self.date = dataModel.date
        self.incomeType = dataModel.incomeType
        self.sum = dataModel.sum
        self.cash = dataModel.cash
        self.card = dataModel.card
    }
}
