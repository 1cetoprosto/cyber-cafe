//
//  PurchaseDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class PurchaseDetailsViewModel: PurchaseDetailsViewModelType {
    
    private var purchase: PurchaseModel
    //var newModel: Bool
    
    var purchaseDate: Date { return purchase.date }
    var purchaseName: String { return purchase.name }
    var purchaseSum: String { return purchase.sum.description }
    
    func savePurchaseModel(purchaseDate: Date, purchaseName: String?, purchaseSum: String?) {

        let purchaseName = purchaseName ?? ""
        let purchaseSum = purchaseSum?.doubleOrZero
        
        //if newModel {
            purchase.date = purchaseDate
            purchase.name = purchaseName
            purchase.sum = purchaseSum ?? 0.0
            
        if purchase.id.isEmpty {
            purchase.id = UUID().uuidString
            DomainDatabaseService.shared.savePurchase(purchase: purchase) { success in
                if success {
                    print("Purchase saved successfully")
                } else {
                    print("Failed to save Purchase")
                }
            }
        } else {
            DomainDatabaseService.shared.updatePurchase(model: purchase, date: purchaseDate, name: purchaseName, sum: purchaseSum ?? 0.0)
        }
    }
    
    init(purchase: PurchaseModel) {
        self.purchase = purchase
        //self.newModel = true
    }
    
}
