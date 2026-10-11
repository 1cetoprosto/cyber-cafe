import Foundation

enum DomainProductCategoryError: Error {
    case saveFailed
}

protocol ProductCategoryDataServiceProtocol {
    func saveCategory(_ category: ProductCategoryModel) async throws
}

final class DomainProductCategoryDataService: ProductCategoryDataServiceProtocol {
    @MainActor
    func saveCategory(_ category: ProductCategoryModel) async throws {
        let firModel = FIRProductCategoryModel(dataModel: category)

        try await FirestoreDatabaseService.shared.update(
            firModel: firModel,
            collection: FirebaseCollections.productCategories,
            documentId: category.id
        )
    }
}
