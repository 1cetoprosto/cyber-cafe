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
    func updateProductPrice(_ productPrice: ProductsPriceModel, name: String, price: Double) async throws
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
    func updateProductPrice(_ productPrice: ProductsPriceModel, name: String, price: Double) async throws {
        var updatedModel = FIRProductsPriceModel(dataModel: productPrice)
        updatedModel.name = name
        updatedModel.price = price
        
        try await withCheckedThrowingContinuation { continuation in
            FirestoreDatabaseService.shared.update(
                firModel: updatedModel,
                collection: FirebaseCollections.productsPrice,
                documentId: productPrice.id
            ) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
