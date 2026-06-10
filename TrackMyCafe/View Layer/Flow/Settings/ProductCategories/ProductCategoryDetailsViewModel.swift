import Foundation

final class ProductCategoryDetailsViewModel: ProductCategoryDetailsViewModelType, Loggable {
    private enum ImageUpdate {
        case unchanged
        case delete
        case replace(Data)
    }

    private let screenTitle: String
    private var model: ProductCategoryModel
    private let dataService: ProductCategoryDataServiceProtocol
    private let imageStorage: ImageStorageServiceProtocol

    private var imageUpdate: ImageUpdate = .unchanged

    init(
        title: String,
        model: ProductCategoryModel,
        dataService: ProductCategoryDataServiceProtocol,
        imageStorage: ImageStorageServiceProtocol = FirebaseImageStorageService.shared
    ) {
        self.screenTitle = title
        self.model = model
        self.dataService = dataService
        self.imageStorage = imageStorage
    }

    var title: String { screenTitle }
    var name: String { model.name }
    var imagePath: String? { model.imagePath }

    func setName(_ name: String?) {
        model.name = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func setSelectedImageData(_ data: Data?) {
        guard let data else { return }
        imageUpdate = .replace(data)
    }

    func markImageDeleted() {
        let hadPersistedImage = (model.imagePath?.isEmpty == false)
        imageUpdate = hadPersistedImage ? .delete : .unchanged
        model.imagePath = nil
    }

    @MainActor
    func save() async throws {
        let trimmedName = model.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw DomainProductCategoryError.saveFailed }
        model.name = trimmedName

        var pendingDeletePath: String?

        switch imageUpdate {
        case .unchanged:
            break
        case .delete:
            pendingDeletePath = model.imagePath
            model.imagePath = nil
        case .replace(let data):
            let path = ImageStoragePaths.productCategoryImagePath(categoryId: model.id)
            do {
                try await imageStorage.upload(data: data, toPath: path, contentType: "image/jpeg")
            } catch {
                logger.error(
                    "Product category image upload failed for \(self.model.id): \(error.localizedDescription)"
                )
                throw NSError(
                    domain: "ProductCategoryImageUpload",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Image upload failed: \(error.localizedDescription)"
                    ]
                )
            }
            model.imagePath = path
        }

        do {
            try await dataService.saveCategory(model)
        } catch {
            logger.error("Failed to save product category \(self.model.id): \(error.localizedDescription)")
            throw NSError(
                domain: "ProductCategoryFirestoreSave",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firestore save failed: \(error.localizedDescription)"
                ]
            )
        }

        if let pendingDeletePath {
            Task {
                _ = try? await self.imageStorage.delete(atPath: pendingDeletePath)
            }
        }
        imageUpdate = .unchanged
    }
}
