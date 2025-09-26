//
//  FIROrdersModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import FirebaseFirestoreSwift
import Foundation

struct FIROrderModel: Codable {
  @DocumentID var id: String?
  var date = Date()
  var type: String = R.string.global.defaultOrderType()
  var sum: Double = 0.0
  var cash: Double = 0.0
  var card: Double = 0.0

  init(dataModel: OrderModel) {
    self.id = dataModel.id
    self.date = dataModel.date
    self.type = dataModel.type
    self.sum = dataModel.sum
    self.cash = dataModel.cash
    self.card = dataModel.card
  }

}

//extension FIROrderModel {
//    static var empty = FIROrderModel(ordersModel: RealmOrderModel())
//}
