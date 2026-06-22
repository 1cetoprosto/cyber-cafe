//
//  JournalEntryModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.06.2026.
//

import Foundation

struct JournalEntryModel: Identifiable, Codable {
    let id: String
    let date: Date
    let account: PaymentAccount
    let amount: Double
    let sourceType: JournalSourceType
    let sourceId: String
    let note: String?

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        account: PaymentAccount,
        amount: Double,
        sourceType: JournalSourceType,
        sourceId: String,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.account = account
        self.amount = amount
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.note = note
    }

    init(firebaseModel: FIRJournalEntryModel) {
        self.id = firebaseModel.id ?? ""
        self.date = firebaseModel.date
        self.account = firebaseModel.account
        self.amount = firebaseModel.amount
        self.sourceType = firebaseModel.sourceType
        self.sourceId = firebaseModel.sourceId
        self.note = firebaseModel.note
    }
}
