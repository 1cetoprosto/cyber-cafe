//
//  ProductDetailsViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 09.11.2025.
//

import Foundation

final class ProductDetailsViewModel: ProductDetailsViewModelType, Loggable {
    private enum ImageUpdate {
        case unchanged
        case delete
        case replace(Data)
    }

    private var model: ProductsPriceModel
    private let dataService: ProductPriceDataServiceProtocol
    private let ingredientService: IngredientDataServiceProtocol
    private let imageStorage: ImageStorageServiceProtocol

    private var imageUpdate: ImageUpdate = .unchanged

    var productName: String { model.name }
    var productPrice: Double { model.price }
    var currentRecipe: [RecipeItemModel] { model.recipe }
    var allIngredients: [IngredientModel] = []
    var categoryId: String? { model.categoryId }
    var imagePath: String? { model.imagePath }

    var onRecipeChanged: (() -> Void)?
    var onIngredientsLoaded: (() -> Void)?

    init(
        model: ProductsPriceModel,
        dataService: ProductPriceDataServiceProtocol,
        ingredientService: IngredientDataServiceProtocol = DomainIngredientDataService.shared,
        imageStorage: ImageStorageServiceProtocol = FirebaseImageStorageService.shared
    ) {
        self.model = model
        self.dataService = dataService
        self.ingredientService = ingredientService
        self.imageStorage = imageStorage
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

    func fetchIngredients() async {
        do {
            let ingredients = try await ingredientService.fetchIngredients()
            self.allIngredients = ingredients
            await MainActor.run {
                self.onIngredientsLoaded?()
            }
        } catch {
            logger.error("Failed to fetch ingredients: \(error)")
        }
    }

    func hasIngredient(_ ingredient: IngredientModel) -> Bool {
        return model.recipe.contains(where: { $0.ingredientId == ingredient.id })
    }

    func addRecipeItem(ingredient: IngredientModel, quantity: Double, overwrite: Bool = false) {
        guard quantity > 0 else { return }

        if let index = model.recipe.firstIndex(where: { $0.ingredientId == ingredient.id }) {
            if overwrite {
                var existingItem = model.recipe[index]
                existingItem.quantity = quantity
                model.recipe[index] = existingItem
                onRecipeChanged?()
            }
        } else {
            let item = RecipeItemModel(
                ingredientId: ingredient.id, ingredientName: ingredient.name, quantity: quantity,
                unit: ingredient.unit)
            model.recipe.append(item)
            onRecipeChanged?()
        }
    }

    func removeRecipeItem(at index: Int) {
        guard index >= 0 && index < model.recipe.count else { return }
        model.recipe.remove(at: index)
        onRecipeChanged?()
    }

    func updateRecipeItem(at index: Int, quantity: Double) {
        guard index >= 0 && index < model.recipe.count else { return }
        var item = model.recipe[index]
        item.quantity = quantity
        model.recipe[index] = item
        onRecipeChanged?()
    }

    func setCategoryId(_ id: String?) {
        model.categoryId = id
    }

    func validate(name: String?, priceText: String?) -> Bool {
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        guard let price = parsedPrice(from: priceText), price >= 0 else { return false }
        return true
    }

    func parsedPrice(from text: String?) -> Double? {
        guard let text = text, !text.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: text)?.doubleValue { return number }
        return Double(text.replacingOccurrences(of: ",", with: "."))
    }

    @MainActor
    func saveProductPrice(name: String?, price: Double?) async throws {
        let nameValue = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let priceValue = price ?? 0.0

        model.name = nameValue
        model.price = priceValue

        let isNew = model.id.isEmpty
        if isNew {
            model.id = UUID().uuidString
        }

        var pendingDeletePath: String?

        switch imageUpdate {
        case .unchanged:
            break
        case .delete:
            pendingDeletePath = model.imagePath
            model.imagePath = nil
        case .replace(let data):
            let path = ImageStoragePaths.productImagePath(productId: model.id)
            do {
                try await imageStorage.upload(data: data, toPath: path, contentType: "image/jpeg")
            } catch {
                logger.error(
                    "Product image upload failed for \(self.model.id): \(error.localizedDescription)"
                )
                throw NSError(
                    domain: "ProductImageUpload",
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
            if isNew {
                try await dataService.saveProductPrice(model)
                logger.notice("Product price \(model.id) saved successfully")
            } else {
                try await dataService.updateProductPrice(model, name: nameValue, price: priceValue)
                logger.notice("Product price \(model.id) updated successfully")
            }
        } catch {
            logger.error("Failed to save product price \(self.model.id): \(error.localizedDescription)")
            throw NSError(
                domain: "ProductFirestoreSave",
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
