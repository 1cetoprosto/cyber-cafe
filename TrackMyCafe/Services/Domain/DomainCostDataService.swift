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
  func saveCost(_ cost: OpexExpenseModel) async throws
  func updateCost(_ cost: OpexExpenseModel, date: Date, name: String, sum: Double) async
}

final class DomainCostDataService: CostDataServiceProtocol {
  @MainActor
  func saveCost(_ cost: OpexExpenseModel) async throws {
    try await withCheckedThrowingContinuation { continuation in
      DomainDatabaseService.shared.saveOpexExpense(model: cost) { id in
        if id != nil {
          continuation.resume()
        } else {
          continuation.resume(throwing: DomainCostError.saveFailed)
        }
      }
    }
  }

  @MainActor
  func updateCost(_ cost: OpexExpenseModel, date: Date, name: String, sum: Double) async {
      let updatedCost = OpexExpenseModel(
          id: cost.id,
          date: date,
          categoryId: cost.categoryId,
          amount: sum,
          note: name
      )
      DomainDatabaseService.shared.updateOpexExpense(model: updatedCost)
  }
}
