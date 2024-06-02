//
//  SettingListItemViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import Foundation

protocol SettingListItemViewModelType: AnyObject {
    var purchaseDate: String { get } // "05.09.21"
    var purchaseName: String { get } // "Milk"
    var purchaseSum: String { get } // "640"
    var purchaseLabel: String { get } // "Sum:"
}
