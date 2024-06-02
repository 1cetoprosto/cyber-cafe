//
//  OrderListItemViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol OrderListItemViewModelType: AnyObject {
    var productsName: String { get }
    var ordersSum: String { get }
    var ordersLabel: String { get }
    var cashSum: String { get }
    var cashLabel: String { get }
}
