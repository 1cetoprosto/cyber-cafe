//
//  DailyBalanceModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.06.2026.
//

import Foundation

struct DailyBalanceModel: Identifiable, Codable {
    let id: String
    let date: Date
    let account: PaymentAccount
    let balance: Double
    let delta: Double

    init(
        id: String? = nil,
        date: Date = Date(),
        account: PaymentAccount,
        balance: Double,
        delta: Double
    ) {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        self.id = id ?? Self.makeDocumentId(for: account, date: normalizedDate)
        self.date = normalizedDate
        self.account = account
        self.balance = balance
        self.delta = delta
    }

    init(firebaseModel: FIRDailyBalanceModel) {
        self.id = firebaseModel.id ?? Self.makeDocumentId(
            for: firebaseModel.account,
            date: firebaseModel.date
        )
        self.date = Calendar.current.startOfDay(for: firebaseModel.date)
        self.account = firebaseModel.account
        self.balance = firebaseModel.balance
        self.delta = firebaseModel.delta
    }

    static func makeDocumentId(for account: PaymentAccount, date: Date) -> String {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let timestamp = Int64(normalizedDate.timeIntervalSince1970)
        let timestampString = String(format: "%010lld", timestamp)
        return "\(account.rawValue)_\(timestampString)"
    }
}
