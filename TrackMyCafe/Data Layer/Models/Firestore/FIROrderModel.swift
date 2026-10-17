//
//  FIROrdersModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import FirebaseFirestore
import Foundation

struct FIROrderModel: Codable {
    @DocumentID var id: String?
    var date = Date()
    var type: String = R.string.global.defaultOrderType()
    var sum: Double = 0.0
    var cash: Double = 0.0
    var card: Double = 0.0
    var totalCost: Double?
    var inventoryTracking: Bool?
    var note: String?
    /// Firebase ref of the employee who created the order. `nil` for legacy orders.
    var createdBy: String?

    init(dataModel: OrderModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.type = dataModel.type
        self.sum = dataModel.sum
        self.cash = dataModel.cash
        self.card = dataModel.card
        self.totalCost = dataModel.totalCost
        self.inventoryTracking = dataModel.inventoryTracking
        self.note = dataModel.note
        self.createdBy = dataModel.createdBy
    }

}
