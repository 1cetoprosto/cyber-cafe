//
//  OpexExpenseModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

// MARK: - OpexExpenseModel
//
// Domain model for operational expenses (rent, utilities, salaries, etc.).
// See `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.2 (OpexExpense).
//
// Target shape (spec): id, date, amount, note?
//
// Intentional v1.x deviations from the target spec:
// - `categoryId` links the expense to an `OpexCategoryModel` for reporting.
// - `paymentAccount` supports cash/card split tracking (v1.1.x).

struct OpexExpenseModel: Identifiable, Codable {
    let id: String
    let date: Date
    let categoryId: String
    let amount: Double
    let paymentAccount: PaymentAccount?
    let note: String?

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        categoryId: String,
        amount: Double,
        paymentAccount: PaymentAccount? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.categoryId = categoryId
        self.amount = amount
        self.paymentAccount = paymentAccount
        self.note = note
    }
}
