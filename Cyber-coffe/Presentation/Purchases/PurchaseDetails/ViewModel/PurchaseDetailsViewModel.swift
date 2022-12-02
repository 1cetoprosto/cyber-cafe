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
    
    var purchaseDate: Date { return purchase.date }
    var purchaseName: String { return purchase.good }
    var purchaseSum: String { return purchase.sum.description }
    
    func savePurchaseModel(purchaseDate: Date, purchaseName: String?, purchaseSum: String?) {

        let purchaseName = purchaseName ?? ""
        let purchaseSum = Double(purchaseSum ?? "0.0") ?? 0.0
        
        if newModel {
            purchase.date = purchaseDate
            purchase.good = purchaseName
            purchase.sum = purchaseSum
            
            if let id = FIRFirestoreService
                .shared
                .create(firModel: FIRPurchaseModel(purchaseModel: purchase), collection: "purchase") {
                purchase.id = id
                purchase.synchronized = true
            }
            
            DatabaseManager.shared.save(model: purchase)
            purchase = PurchaseModel()
        } else {
            let purchaseSynchronized = FIRFirestoreService
                .shared
                .update(firModel: FIRPurchaseModel(purchaseId: purchase.id,
                                                   purchaseDate: purchaseDate,
                                                   purchaseGood: purchaseName,
                                                   purchaseSum: purchaseSum),
                        collection: "purchase", documentId: purchase.id)
            
            DatabaseManager.shared.updatePurchaseModel(model: purchase,
                                                       purchaseDate: purchaseDate,
                                                       purchaseName: purchaseName,
                                                       purchaseSum: purchaseSum,
                                                       purchaseSynchronized: purchaseSynchronized)
        }
    }
    
    init(purchase: PurchaseModel) {
        self.purchase = purchase
        self.newModel = true
    }
    
}
