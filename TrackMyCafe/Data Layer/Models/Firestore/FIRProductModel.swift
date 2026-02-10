//
//  FIRProductModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 30.04.2022.
//

import FirebaseFirestoreSwift
import Foundation

struct FIRProductModel: Codable {
    @DocumentID var id: String?
    var productId: String?
    var orderId: String?
    var date = Date()
    var name: String = ""
    var quantity: Int = 0
    var price: Double = 0.0
    var amount: Double = 0.0
    var costPrice: Double = 0.0
    var costSum: Double = 0.0

    init(dataModel: ProductOfOrderModel) {
        self.id = dataModel.id
        self.productId = dataModel.productId
        self.orderId = dataModel.orderId
        self.date = dataModel.date
        self.name = dataModel.name
        self.quantity = dataModel.quantity
        self.price = dataModel.price
        self.amount = dataModel.sum
        self.costPrice = dataModel.costPrice
        self.costSum = dataModel.costSum
    }
}

//extension FIRProductModel {
//    static var empty = FIRProductModel(productModel: RealmProductModel())
//}
