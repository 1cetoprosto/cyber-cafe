//
//  SaleGoodListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

class SaleGoodListItemViewModel: SaleGoodListItemViewModelType {
    
    private var saleGood: SaleGoodModel
    private var atIndex: Int
    
    var goodLabel: String { return saleGood.name}
    
    var quantityLabel: String { return saleGood.quantity.description}
    
    var goodStepperValue: Double { return saleGood.quantity.double}
    
    var goodStepperTag: Int { return atIndex}
    
    init(saleGood: SaleGoodModel, for atIndex: Int) {
        self.saleGood = saleGood
        self.atIndex = atIndex
    }
}
