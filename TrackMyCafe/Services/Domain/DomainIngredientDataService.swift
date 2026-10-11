//
//  DomainIngredientDataService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import Foundation

enum DomainIngredientError: Error {
    case saveFailed
    case deleteFailed
    case fetchFailed
}

protocol IngredientDataServiceProtocol {
    func fetchIngredients() async throws -> [IngredientModel]
    func saveIngredient(_ ingredient: IngredientModel) async throws
    func deleteIngredient(_ ingredient: IngredientModel) async throws
}

final class DomainIngredientDataService: IngredientDataServiceProtocol {
    static let shared = DomainIngredientDataService()
    
    private init() {}
    
    @MainActor
    func fetchIngredients() async throws -> [IngredientModel] {
        await DomainDatabaseService.shared.fetchIngredients()
    }
    
    @MainActor
    func saveIngredient(_ ingredient: IngredientModel) async throws {
        let success = await DomainDatabaseService.shared.saveIngredient(model: ingredient)
        guard success else {
            throw DomainIngredientError.saveFailed
        }
    }
    
    @MainActor
    func deleteIngredient(_ ingredient: IngredientModel) async throws {
        let success = await DomainDatabaseService.shared.deleteIngredient(model: ingredient)
        guard success else {
            throw DomainIngredientError.deleteFailed
        }
    }
}
