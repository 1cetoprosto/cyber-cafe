//
//  OrderItemModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

struct OrderItemModel: Identifiable, Codable {
    let id: String
    let productId: String
    let quantity: Int
    let salePrice: Double    // Price at the moment of sale
    let costPrice: Double    // COGS at the moment of sale
    
    var totalSale: Double { salePrice * Double(quantity) }
    var totalCost: Double { costPrice * Double(quantity) }
    
    init(
        id: String = UUID().uuidString,
        productId: String,
        quantity: Int,
        salePrice: Double,
        costPrice: Double = 0.0 // Can be calculated later or passed during creation
    ) {
        self.id = id
        self.productId = productId
        self.quantity = quantity
        self.salePrice = salePrice
        self.costPrice = costPrice
    }
}
