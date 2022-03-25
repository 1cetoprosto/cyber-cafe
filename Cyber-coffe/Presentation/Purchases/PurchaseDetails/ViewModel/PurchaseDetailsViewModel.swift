//
//  PurchaseDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class PurchaseDetailsViewModel: PurchaseDetailsViewModelType {
    
    private var purchase: PurchaseModel
    var newModel: Bool
    
    var purchaseDate: Date { return purchase.purchaseDate }
    var purchaseName: String { return purchase.purchaseGood }
    var purchaseSum: String { return purchase.purchaseSum.description }
    
    func savePurchaseModel(purchaseDate: Date, purchaseName: String?, purchaseSum: String?) {
//        purchaseDate = purchasedatePiker.date
        let purchaseName = purchaseName ?? ""
        let purchaseSum = Double(purchaseSum ?? "0.0") ?? 0.0
        
        if newModel {
            purchase.purchaseDate = purchaseDate
            purchase.purchaseGood = purchaseName
            purchase.purchaseSum = purchaseSum
            
            DatabaseManager.shared.savePurchaseModel(model: purchase)
            purchase = PurchaseModel()
        } else {
            DatabaseManager.shared.updatePurchaseModel(model: purchase,
                                                       purchaseDate: purchaseDate,
                                                       purchaseName: purchaseName,
                                                       purchaseSum: purchaseSum)
        }
    }
    
    init(purchase: PurchaseModel) {
        self.purchase = purchase
        self.newModel = true
    }
    
}
