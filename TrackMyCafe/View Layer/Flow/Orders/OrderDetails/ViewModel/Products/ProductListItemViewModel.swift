//
//  ProductListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

class ProductListItemViewModel: ProductListItemViewModelType {
    
    private var product: ProductOfOrderModel
    private var atIndex: Int
    
    var productLabel: String { return product.name}
    
    var quantityLabel: String { return product.quantity.description}
    
    var productStepperValue: Double { return product.quantity.double}
    
    var productStepperTag: Int { return atIndex}
    
    init(product: ProductOfOrderModel, for atIndex: Int) {
        self.product = product
        self.atIndex = atIndex
    }
}
