//
//  PurchaseListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class PurchaseListItemViewModel: PurchaseListItemViewModelType {
    
    private var purchase: PurchaseModel
    
    var purchaseDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        return dateFormatter.string(from: purchase.date)
    }
    
    var purchaseName: String {
        return purchase.good
    }
    
    var purchaseSum: String {
        return purchase.sum.description
    }
    
    init(purchase: PurchaseModel) {
        self.purchase = purchase
    }
}
