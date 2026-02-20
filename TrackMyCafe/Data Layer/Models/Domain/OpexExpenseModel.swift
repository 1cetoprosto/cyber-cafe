//
//  OpexExpenseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

struct OpexExpenseModel: Identifiable, Codable {
    let id: String
    let date: Date
    let categoryId: String
    let amount: Double
    let note: String?
    
    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        categoryId: String,
        amount: Double,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.categoryId = categoryId
        self.amount = amount
        self.note = note
    }
}
