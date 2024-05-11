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
    var salesDate = Date()
    var salesTypeOfDonation: String = "Sunday service"
    var salesSum: Double = 0.0
    var salesCash: Double = 0.0
    var salesCard: Double = 0.0
    
    //    enum CodingCase: String, CodingKey {
    //        case id
    //        case saleDate
    //        case saleGood
    //        case saleQty
    //        case salePrice
    //        case saleSum
    //    }
    //
    init(salesModel: SalesModel) {
        self.id = salesModel.id
        self.salesDate = salesModel.date
        self.salesTypeOfDonation = salesModel.typeOfDonation
        self.salesSum = salesModel.sum
        self.salesCash = salesModel.cash
        self.salesCard = salesModel.card
    }
    
    init(salesId: String,
         salesDate: Date,
         salesTypeOfDonation: String,
         salesSum: Double,
         salesCash: Double,
         salesCard: Double) {
        self.id = salesId
        self.salesDate = salesDate
        self.salesTypeOfDonation = salesTypeOfDonation
        self.salesSum = salesSum
        self.salesCash = salesCash
        self.salesCard = salesCard
    }
    
}

extension FIRDailySalesModel {
    static var empty = FIRDailySalesModel(salesModel: SalesModel())
}

