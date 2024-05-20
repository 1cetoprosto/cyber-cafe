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
    var purchaseName: String { return purchase.name }
    var purchaseSum: String { return purchase.sum.description }
    
    func savePurchaseModel(purchaseDate: Date, purchaseName: String?, purchaseSum: String?) {

        let purchaseName = purchaseName ?? ""
        let purchaseSum = Double(purchaseSum ?? "0.0") ?? 0.0
        
        if newModel {
            purchase.date = purchaseDate
            purchase.name = purchaseName
            purchase.sum = purchaseSum
            
//            if let id = FirestoreDatabaseService
//                .shared
//                .create(firModel: FIRPurchaseModel(purchaseModel: purchase), collection: "purchase") {
//                purchase.id = id
//            }
            
            RealmDatabaseService.shared.save(model: RealmPurchaseModel(dataModel: purchase))
            purchase = PurchaseModel(id: "", date: Date(), name: "", sum: 0)
        } else {
//            let purchaseSynchronized = FirestoreDatabaseService
//                .shared
//                .update(firModel: FIRPurchaseModel(purchaseId: purchase.id,
//                                                   purchaseDate: purchaseDate,
//                                                   purchaseGood: purchaseName,
//                                                   purchaseSum: purchaseSum),
//                        collection: "purchase", documentId: purchase.id)
            
            RealmDatabaseService.shared.updatePurchase(model: RealmPurchaseModel(dataModel: purchase),
                                                       date: purchaseDate,
                                                       name: purchaseName,
                                                       sum: purchaseSum)
        }
    }
    
    init(purchase: PurchaseModel) {
        self.purchase = purchase
        self.newModel = true
    }
    
}
