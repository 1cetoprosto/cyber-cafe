//
//  FIRGoodsPriceModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRGoodsPriceModel: Codable {
    @DocumentID var id: String?
    var good: String = ""
    var price: Double = 0.0
    
    //    enum CodingCase: String, CodingKey {
    //        case id
    //        case saleDate
    //        case saleGood
    //        case saleQty
    //        case salePrice
    //        case saleSum
    //    }
    //
    init(goodsPriceModel: GoodsPriceModel) {
        self.id = goodsPriceModel.id
        self.good = goodsPriceModel.good
        self.price = goodsPriceModel.price
    }
    
    init(id: String?,
         good: String,
         price: Double) {
        self.id = id
        self.good = good
        self.price = price
    }
    
}

extension FIRGoodsPriceModel {
    static var empty = FIRGoodsPriceModel(goodsPriceModel: GoodsPriceModel())
}
