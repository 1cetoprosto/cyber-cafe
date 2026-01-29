//
//  IngredientListViewModelType.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation

protocol IngredientListViewModelType {
    var title: String { get }
    var ingredients: [IngredientModel] { get }
    var onIngredientsUpdated: (() -> Void)? { get set }
    
    func fetchIngredients() async
    func deleteIngredient(at index: Int) async
    func createIngredient(name: String, cost: Double, stock: Double, unit: MeasurementUnit) async
}
