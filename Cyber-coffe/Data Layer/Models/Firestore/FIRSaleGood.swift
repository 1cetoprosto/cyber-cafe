//
//  SaleGoodItem.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 30.04.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRSaleGoodModel: Codable {
    @DocumentID var id: String?
    var saleDate = Date()
    var saleGood: String = ""
    var saleQty: Int = 0
    var salePrice: Double = 0.0
    var saleSum: Double = 0.0
    
//    enum CodingCase: String, CodingKey {
//        case id
//        case saleDate
//        case saleGood
//        case saleQty
//        case salePrice
//        case saleSum
//    }
//
    init(saleGoodModel: SaleGoodModel) {
        self.id = saleGoodModel.id
        self.saleDate = saleGoodModel.date
        self.saleGood = saleGoodModel.saleGood
        self.saleQty = saleGoodModel.saleQty
        self.salePrice = saleGoodModel.salePrice
        self.saleSum = saleGoodModel.saleSum
    }
    
    init(saleId: String,
         saleDate: Date,
         saleGood: String,
         saleQty: Int,
         salePrice: Double,
         saleSum: Double) {
        self.id = saleId
        self.saleDate = saleDate
        self.saleGood = saleGood
        self.saleQty = saleQty
        self.salePrice = salePrice
        self.saleSum = saleSum
    }
    
}

extension FIRSaleGoodModel {
    static var empty = FIRSaleGoodModel(saleGoodModel: SaleGoodModel())
}
