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
        return try await withCheckedThrowingContinuation { continuation in
            DomainDatabaseService.shared.fetchIngredients { ingredients in
                continuation.resume(returning: ingredients)
            }
        }
    }
    
    @MainActor
    func saveIngredient(_ ingredient: IngredientModel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DomainDatabaseService.shared.saveIngredient(model: ingredient) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: DomainIngredientError.saveFailed)
                }
            }
        }
    }
    
    @MainActor
    func deleteIngredient(_ ingredient: IngredientModel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DomainDatabaseService.shared.deleteIngredient(model: ingredient) { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: DomainIngredientError.deleteFailed)
                }
            }
        }
    }
}
