//
//  OpexCategoryModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import Foundation

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
