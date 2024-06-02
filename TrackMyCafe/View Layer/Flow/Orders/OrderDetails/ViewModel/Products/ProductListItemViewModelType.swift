//
//  ProductListItemViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

protocol ProductListItemViewModelType: AnyObject {
    var productLabel: String { get }
    var quantityLabel: String { get }
    var productStepperValue: Double { get }
    var productStepperTag: Int { get }
}
