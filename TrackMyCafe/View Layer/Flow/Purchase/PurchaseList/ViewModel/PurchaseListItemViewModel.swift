//
//  PurchaseListItemViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

protocol PurchaseListItemViewModelType {
    var name: String { get }
    var date: String { get }
    var quantity: String { get }
    var price: String { get }
    var total: String { get }
}

class PurchaseListItemViewModel: PurchaseListItemViewModelType {
    private var purchase: PurchaseModel
    private var ingredientName: String
    
    init(purchase: PurchaseModel, ingredientName: String) {
        self.purchase = purchase
        self.ingredientName = ingredientName
    }
    
    var name: String {
        return ingredientName
    }
    
    var date: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: purchase.date)
    }
    
    var quantity: String {
        return String(format: "%.2f", purchase.quantity)
    }
    
    var price: String {
        return String(format: "%.2f", purchase.price)
    }
    
    var total: String {
        return String(format: "%.2f", purchase.totalCost)
    }
}
