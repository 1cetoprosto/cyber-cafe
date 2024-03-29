//
//  FIRSalesModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRSalesModel: Codable {
    @DocumentID var id: String?
    var salesDate = Date()
    var salesTypeOfDonation: String = "Sunday service"
    var salesSum: Double = 0.0
    var salesCash: Double = 0.0
    
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
    }
    
    init(salesId: String,
         salesDate: Date,
         salesTypeOfDonation: String,
         salesSum: Double,
         salesCash: Double) {
        self.id = salesId
        self.salesDate = salesDate
        self.salesTypeOfDonation = salesTypeOfDonation
        self.salesSum = salesSum
        self.salesCash = salesCash
    }
    
}

extension FIRSalesModel {
    static var empty = FIRSalesModel(salesModel: SalesModel())
}

