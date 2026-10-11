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
        let success = await DomainDatabaseService.shared.saveProductsPrice(productPrice: productPrice)
        guard success else {
            throw DomainProductPriceError.saveFailed
        }
    }
    
    @MainActor
    func updateProductPrice(_ productPrice: ProductsPriceModel, name: String, price: Double) async throws {
        var updatedModel = FIRProductsPriceModel(dataModel: productPrice)
        updatedModel.name = name
        updatedModel.price = price
        
        try await FirestoreDatabaseService.shared.update(
            firModel: updatedModel,
            collection: FirebaseCollections.productsPrice,
            documentId: productPrice.id
        )
    }
}
