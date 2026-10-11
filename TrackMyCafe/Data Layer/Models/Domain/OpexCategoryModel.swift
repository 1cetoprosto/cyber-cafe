//
//  OpexCategoryModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

// MARK: - OpexCategoryModel
//
// Lookup model for Opex expense categories.
// Related to `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.2 (OpexExpense)
// and referenced by `OpexExpenseModel.categoryId`.

struct OpexCategoryModel: Identifiable, Codable {
    let id: String
    let name: String
    let iconName: String?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
    }
}
