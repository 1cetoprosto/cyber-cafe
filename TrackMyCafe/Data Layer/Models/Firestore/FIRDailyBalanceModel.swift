//
//  FIRDailyBalanceModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.06.2026.
//

import FirebaseFirestoreSwift
import Foundation

struct FIRDailyBalanceModel: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var account: PaymentAccount
    var balance: Double
    var delta: Double

    init(dataModel: DailyBalanceModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.account = dataModel.account
        self.balance = dataModel.balance
        self.delta = dataModel.delta
    }
}
