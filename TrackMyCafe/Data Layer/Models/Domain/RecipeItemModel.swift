//
//  RecipeItemModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation

struct RecipeItemModel: Identifiable, Codable {
  var id: String
  var ingredientId: String
  var ingredientName: String  // Cached name for UI display
  var quantity: Double
  var unit: MeasurementUnit  // Should match ingredient unit

  init(
    id: String = UUID().uuidString,
    ingredientId: String,
    ingredientName: String,
    quantity: Double,
    unit: MeasurementUnit
  ) {
    self.id = id
    self.ingredientId = ingredientId
    self.ingredientName = ingredientName
    self.quantity = quantity
    self.unit = unit
  }

  init(realmModel: RealmRecipeItemModel) {
    self.id = realmModel.id
    self.ingredientId = realmModel.ingredientId
    self.ingredientName = realmModel.ingredientName
    self.quantity = realmModel.quantity
    self.unit = MeasurementUnit(rawValue: realmModel.unit) ?? .pcs
  }

  init(firebaseModel: FIRRecipeItemModel) {
    self.id = firebaseModel.id
    self.ingredientId = firebaseModel.ingredientId
    self.ingredientName = firebaseModel.ingredientName
    self.quantity = firebaseModel.quantity
    self.unit = MeasurementUnit(rawValue: firebaseModel.unit) ?? .pcs
  }
}
