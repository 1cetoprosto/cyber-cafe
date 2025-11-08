//
//  DomainCostDataService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 07.11.2025.
//

import Foundation

enum DomainCostError: Error {
  case saveFailed
}

protocol CostDataServiceProtocol {
  func saveCost(_ cost: CostModel) async throws
  func updateCost(_ cost: CostModel, date: Date, name: String, sum: Double) async
}

final class DomainCostDataService: CostDataServiceProtocol {
  @MainActor
  func saveCost(_ cost: CostModel) async throws {
    try await withCheckedThrowingContinuation { continuation in
      DomainDatabaseService.shared.saveCost(model: cost) { success in
        if success {
          continuation.resume()
        } else {
          continuation.resume(throwing: DomainCostError.saveFailed)
        }
      }
    }
  }

  @MainActor
  func updateCost(_ cost: CostModel, date: Date, name: String, sum: Double) async {
    DomainDatabaseService.shared.updateCost(model: cost, date: date, name: name, sum: sum)
  }
}
