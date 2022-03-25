//
//  SaleListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class SaleListItemViewModel: SaleListItemViewModelType {
    
    private var sale: SalesModel
    
    var goodsName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        return dateFormatter.string(from: sale.salesDate)
    }
    
    var salesSum: String {
        return String(Int(sale.salesSum))
    }
    
    var salesLabel: String {
        return "Sale"
    }
    
    var cashSum: String {
        return String(Int(sale.salesCash))
    }
    
    var cashLabel: String {
        return "Cash"
    }
    
    init(sale: SalesModel) {
        self.sale = sale
    }
}
