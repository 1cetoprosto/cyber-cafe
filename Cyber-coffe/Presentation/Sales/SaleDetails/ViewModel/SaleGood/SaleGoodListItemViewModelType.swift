//
//  SaleGoodListItemViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

protocol SaleGoodListItemViewModelType: AnyObject {
    var goodLabel: String { get }
    var quantityLabel: String { get }
    var goodStepperValue: Double { get }
    var goodStepperTag: Int { get }
}
