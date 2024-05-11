//
//  SaleListItemViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol SaleListItemViewModelType: AnyObject {
    var goodsName: String { get }
    var salesSum: String { get }
    var salesLabel: String { get }
    var cashSum: String { get }
    var cashLabel: String { get }
}
