//
//  FIRSalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRDailySalesModel: Codable {
    @DocumentID var id: String?
    var date = Date()
    var incomeType: String = "Sunday service"
    var sum: Double = 0.0
    var cash: Double = 0.0
    var card: Double = 0.0
    
    init(dataModel: DailySalesModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.incomeType = dataModel.incomeType
        self.sum = dataModel.sum
        self.cash = dataModel.cash
        self.card = dataModel.card
    }
    
}

//extension FIRDailySalesModel {
//    static var empty = FIRDailySalesModel(salesModel: RealmDailySalesModel())
//}

