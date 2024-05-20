//
//  SaleListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class SaleListItemViewModel: SaleListItemViewModelType {
    
    private var model: DailySalesModel
    
    var goodsName: String {
        return model.incomeType
    }
    
    var salesSum: String {
        return String(Int(model.sum))
    }
    
    var salesLabel: String {
        return "Sale"
    }
    
    var cashSum: String {
        return String(Int(model.cash))
    }
    
    var cashLabel: String {
        return "Cash"
    }
    
    init(model: DailySalesModel) {
        self.model = model
    }
}
