//
//  OrderListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class OrderListItemViewModel: OrderListItemViewModelType {

  private var model: OrderModel

  var productsName: String {
    return model.type
  }

  var ordersSum: String {
    return model.sum.currency
  }

  var ordersLabel: String {
    return R.string.global.order()
  }

  var cashSum: String {
    return model.cash.currency
  }

  var cashLabel: String {
    return R.string.global.cash()
  }

  init(model: OrderModel) {
    self.model = model
  }
}
