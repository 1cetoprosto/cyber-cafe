//
//  SaleGoodListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

class SaleGoodListItemViewModel: SaleGoodListItemViewModelType {
    
    private var saleGood: SaleGood
    private var atIndex: Int
    
    var goodLabel: String { return saleGood.saleGood}
    
    var quantityLabel: String { return saleGood.saleQty.description}
    
    var goodStepperValue: Double { return Double(saleGood.saleQty)}
    
    var goodStepperTag: Int { return atIndex}
    
    init(saleGood: SaleGood, for atIndex: Int) {
        self.saleGood = saleGood
        self.atIndex = atIndex
    }
}
