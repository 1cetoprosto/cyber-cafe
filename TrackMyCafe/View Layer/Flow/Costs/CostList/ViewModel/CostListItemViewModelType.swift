//
//  CostListItemViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol CostListItemViewModelType: AnyObject {
    var costDate: String { get } // "05.09.21"
    var costName: String { get } // "Milk"
    var costSum: String { get } // "640"
}
