//
//  DomainProductPriceDataService.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 09.11.2025.
//

import Foundation

enum DomainProductPriceError: Error {
  case saveFailed
}

protocol ProductPriceDataServiceProtocol {
  func saveProductPrice(_ productPrice: ProductsPriceModel) async throws
  func updateProductPrice(_ productPrice: ProductsPriceModel, name: String, price: Double) async
}

final class DomainProductPriceDataService: ProductPriceDataServiceProtocol {
  @MainActor
  func saveProductPrice(_ productPrice: ProductsPriceModel) async throws {
    try await withCheckedThrowingContinuation { continuation in
      DomainDatabaseService.shared.saveProductsPrice(productPrice: productPrice) { success in
        if success {
          continuation.resume()
        } else {
          continuation.resume(throwing: DomainProductPriceError.saveFailed)
        }
      }
    }
  }

  @MainActor
  func updateProductPrice(_ productPrice: ProductsPriceModel, name: String, price: Double) async {
    DomainDatabaseService.shared.updateProductsPrice(model: productPrice, name: name, price: price)
  }
}
