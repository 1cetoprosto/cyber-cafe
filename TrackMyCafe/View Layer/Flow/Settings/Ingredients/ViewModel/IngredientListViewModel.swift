//
//  IngredientListViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation

final class IngredientListViewModel: IngredientListViewModelType, Loggable {
    var title: String { R.string.global.ingredients() }
    
    private(set) var ingredients: [IngredientModel] = []
    private let dataService: IngredientDataServiceProtocol
    
    var onIngredientsUpdated: (() -> Void)?
    
    init(dataService: IngredientDataServiceProtocol = DomainIngredientDataService.shared) {
        self.dataService = dataService
    }
    
    @MainActor
    func fetchIngredients() async {
        do {
            self.ingredients = try await dataService.fetchIngredients()
            self.onIngredientsUpdated?()
        } catch {
            logger.error("Failed to fetch ingredients: \(error)")
        }
    }
    
    @MainActor
    func deleteIngredient(at index: Int) async {
        guard index >= 0 && index < ingredients.count else { return }
        let ingredient = ingredients[index]
        
        do {
            try await dataService.deleteIngredient(ingredient)
            self.ingredients.remove(at: index)
            self.onIngredientsUpdated?()
        } catch {
            logger.error("Failed to delete ingredient: \(error)")
        }
    }
    
    @MainActor
    func createIngredient(name: String, cost: Double, stock: Double, unit: MeasurementUnit) async {
        let newIngredient = IngredientModel(
            id: UUID().uuidString,
            name: name,
            averageCost: cost,
            stockQuantity: stock,
            unit: unit
        )
        
        do {
            try await dataService.saveIngredient(newIngredient)
            self.ingredients.append(newIngredient)
            self.onIngredientsUpdated?()
        } catch {
            logger.error("Failed to save ingredient: \(error)")
        }
    }
}
