//
//  FIRJournalEntryModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.06.2026.
//

import FirebaseFirestoreSwift
import Foundation

struct FIRJournalEntryModel: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var account: PaymentAccount
    var amount: Double
    var sourceType: JournalSourceType
    var sourceId: String
    var note: String?

    init(dataModel: JournalEntryModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.account = dataModel.account
        self.amount = dataModel.amount
        self.sourceType = dataModel.sourceType
        self.sourceId = dataModel.sourceId
        self.note = dataModel.note
    }
}
