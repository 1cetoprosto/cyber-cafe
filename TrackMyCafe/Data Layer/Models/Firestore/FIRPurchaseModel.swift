//
//  FIRPurchaseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRPurchaseModel: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var ingredientId: String
    var quantity: Double
    var price: Double
    var supplierId: String?
    
    init(dataModel: PurchaseModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.ingredientId = dataModel.ingredientId
        self.quantity = dataModel.quantity
        self.price = dataModel.price
        self.supplierId = dataModel.supplierId
    }
}
