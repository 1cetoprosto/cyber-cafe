//
//  SaleDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class SaleDetailsViewModel: SaleDetailsViewModelType {
    
    private var sale: SalesModel
    
    var moneyLabel: String {
        return "Money:"
    }
    var moneyTextfield: String { return "Money:" }
    var saleLabel: String { return "Money:" }
    var salesCash: Double { return 0.0 }
    var salesSum: Double { return 0.0 }
    
    init(sale: SalesModel) {
        self.sale = sale
    }
}
