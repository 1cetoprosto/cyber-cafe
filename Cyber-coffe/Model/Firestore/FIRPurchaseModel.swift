//
//  FIRPurchaseModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRPurchaseModel: Codable {
    @DocumentID var id: String?
    var purchaseDate: Date = Date()
    var purchaseGood: String = ""
    var purchaseSum: Double = 0.0
    
    //    enum CodingCase: String, CodingKey {
    //        case id
    //        case saleDate
    //        case saleGood
    //        case saleQty
    //        case salePrice
    //        case saleSum
    //    }
    //
    init(purchaseModel: PurchaseModel) {
        self.id = purchaseModel.purchaseId
        self.purchaseDate = purchaseModel.purchaseDate
        self.purchaseGood = purchaseModel.purchaseGood
        self.purchaseSum = purchaseModel.purchaseSum
    }
    
    init(purchaseId: String,
         purchaseDate: Date,
         purchaseGood: String,
         purchaseSum: Double) {
        self.id = purchaseId
        self.purchaseDate = purchaseDate
        self.purchaseGood = purchaseGood
        self.purchaseSum = purchaseSum
    }
    
}

extension FIRPurchaseModel {
    static var empty = FIRPurchaseModel(purchaseModel: PurchaseModel())
}
