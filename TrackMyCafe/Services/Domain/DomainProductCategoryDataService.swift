import Foundation

enum DomainProductCategoryError: LocalizedError {
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return R.string.global.failedToSaveProductCategory()
        }
    }
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
