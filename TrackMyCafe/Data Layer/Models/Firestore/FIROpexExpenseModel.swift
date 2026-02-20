//
//  FIROpexExpenseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import Foundation
import FirebaseFirestoreSwift

struct FIROpexExpenseModel: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var categoryId: String
    var amount: Double
    var note: String?
    
    init(dataModel: OpexExpenseModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.categoryId = dataModel.categoryId
        self.amount = dataModel.amount
        self.note = dataModel.note
    }
}
