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

        let purchaseName = purchaseName ?? ""
        let purchaseSum = Double(purchaseSum ?? "0.0") ?? 0.0
        
        if newModel {
            purchase.purchaseDate = purchaseDate
            purchase.purchaseGood = purchaseName
            purchase.purchaseSum = purchaseSum
            
            if let id = FirestoreDatabase
                .shared
                .create(firModel: FIRPurchaseModel(purchaseModel: purchase), collection: "purchase") {
                purchase.purchaseId = id
                purchase.purchaseSynchronized = true
            }
            
            DatabaseManager.shared.savePurchaseModel(model: purchase)
            purchase = PurchaseModel()
        } else {
            let purchaseSynchronized = FirestoreDatabase
                .shared
                .update(firModel: FIRPurchaseModel(purchaseId: purchase.purchaseId,
                                                   purchaseDate: purchaseDate,
                                                   purchaseGood: purchaseName,
                                                   purchaseSum: purchaseSum),
                        collection: "purchase", documentId: purchase.purchaseId)
            
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
