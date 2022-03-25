//
//  PurchaseListItemViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol PurchaseListItemViewModelType: AnyObject {
    var purchaseDate: String { get } // "05.09.21"
    var purchaseName: String { get } // "Milk"
    var purchaseSum: String { get } // "640"
    var purchaseLabel: String { get } // "Sum:"
}
