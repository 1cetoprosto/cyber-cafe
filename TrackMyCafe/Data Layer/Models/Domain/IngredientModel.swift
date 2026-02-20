//
//  IngredientModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation

enum MeasurementUnit: String, CaseIterable, Codable {
    case kg = "kg"
    case g = "g"
    case l = "l"
    case ml = "ml"
    case pcs = "pcs"
    
    var localizedName: String {
        switch self {
        case .kg: return R.string.global.unit_kg()
        case .g: return R.string.global.unit_g()
        case .l: return R.string.global.unit_l()
        case .ml: return R.string.global.unit_ml()
        case .pcs: return R.string.global.unit_pcs()
        }
    }
}

struct IngredientModel: Identifiable, Codable {
    var id: String
    var name: String
    var averageCost: Double  // Average cost per unit
    var stockQuantity: Double
    var unit: MeasurementUnit
    
    init(
        id: String = UUID().uuidString,
        name: String,
        averageCost: Double = 0.0,
        stockQuantity: Double = 0.0,
        unit: MeasurementUnit = .pcs
    ) {
        self.id = id
        self.name = name
        self.averageCost = averageCost
        self.stockQuantity = stockQuantity
        self.unit = unit
    }
    
    init(realmModel: RealmIngredientModel) {
        self.id = realmModel.id
        self.name = realmModel.name
        self.averageCost = realmModel.averageCost
        self.stockQuantity = realmModel.stockQuantity
        self.unit = MeasurementUnit(rawValue: realmModel.unit) ?? .pcs
    }
    
    init(firebaseModel: FIRIngredientModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
        self.averageCost = firebaseModel.averageCost
        self.stockQuantity = firebaseModel.stockQuantity
        self.unit = MeasurementUnit(rawValue: firebaseModel.unit) ?? .pcs
    }
}
