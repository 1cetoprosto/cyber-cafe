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
    var name: String = ""
    var price: Double = 0.0
    

    init(dataModel: GoodsPriceModel) {
        self.id = dataModel.id
        self.name = dataModel.name
        self.price = dataModel.price
    }
}

//extension FIRGoodsPriceModel {
//    static var empty = FIRGoodsPriceModel(goodsPriceModel: RealmGoodsPriceModel())
//}
