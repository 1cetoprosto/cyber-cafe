//
//  FIRSaleGoodModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 30.04.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRSaleGoodModel: Codable {
    @DocumentID var id: String?
    var date = Date()
    var name: String = ""
    var quantity: Int = 0
    var price: Double = 0.0
    var amount: Double = 0.0
    
    init(dataModel: SaleGoodModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.name = dataModel.name
        self.quantity = dataModel.quantity
        self.price = dataModel.price
        self.amount = dataModel.sum
    }
}

//extension FIRSaleGoodModel {
//    static var empty = FIRSaleGoodModel(saleGoodModel: RealmSaleGoodModel())
//}
